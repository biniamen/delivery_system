using System.Text.RegularExpressions;
using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Orders;

public sealed partial class OrderService(
    IOrderRepository orders,
    ICatalogueRepository catalogue,
    IUserRepository users,
    IUnitOfWork unitOfWork,
    IClock clock) : IOrderService
{
    private const decimal DemoDeliveryFee = 80m;

    public async Task<OrderResponse> CreateAsync(
        Guid customerId,
        CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        ValidateCreate(request);

        var existing = await orders.GetByIdempotencyKeyAsync(customerId, request.IdempotencyKey.Trim(), cancellationToken);
        if (existing is not null) return Map(existing);

        var requestedIds = request.Lines.Select(line => line.ProductId).Distinct().ToArray();
        var products = await catalogue.GetActiveProductsAsync(requestedIds, cancellationToken);
        if (products.Count != requestedIds.Length)
            throw new ValidationException(new Dictionary<string, string[]> { ["lines"] = ["One or more products are unavailable."] });

        foreach (var requestedLine in request.Lines)
        {
            var product = products[requestedLine.ProductId];
            try
            {
                product.ReserveStock(requestedLine.Quantity);
            }
            catch (InvalidOperationException exception)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["lines"] = [$"{product.Name}: {exception.Message}"]
                });
            }
        }

        var lines = request.Lines.Select(line =>
        {
            var product = products[line.ProductId];
            return new OrderLine(Guid.NewGuid(), product.Id, product.Name, product.Unit, line.Quantity, product.Price);
        });

        var now = clock.UtcNow;
        var order = Order.Create(
            Guid.NewGuid(),
            $"CRV-{now:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}",
            customerId,
            request.IdempotencyKey,
            request.ContactName,
            request.PhoneNumber,
            request.DeliveryAddress,
            request.PaymentMethod,
            DemoDeliveryFee,
            lines,
            now);

        await orders.AddAsync(order, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(order);
    }

    public async Task<IReadOnlyList<OrderSummaryResponse>> ListAsync(
        OrderStatus? status,
        Guid? driverId,
        CancellationToken cancellationToken)
    {
        var found = await orders.ListAsync(status, driverId, cancellationToken);
        return found.Select(MapSummary).ToList();
    }

    public async Task<IReadOnlyList<OrderSummaryResponse>> ListForCustomerAsync(
        Guid customerId,
        CancellationToken cancellationToken)
    {
        var found = await orders.ListForCustomerAsync(customerId, cancellationToken);
        return found.Select(MapSummary).ToList();
    }

    public async Task<OrderResponse> GetAsync(Guid id, CancellationToken cancellationToken) =>
        Map(await GetRequiredAsync(id, cancellationToken));

    public async Task<OrderResponse> AssignAsync(
        Guid id,
        Guid dispatcherId,
        AssignDriverRequest request,
        CancellationToken cancellationToken)
    {
        var driver = await users.GetByIdAsync(request.DriverId, cancellationToken);
        if (driver is null || !driver.IsActive || driver.Role != UserRole.Driver)
            throw new ValidationException(new Dictionary<string, string[]> { ["driverId"] = ["Select an active driver."] });

        var order = await GetRequiredAsync(id, cancellationToken);
        order.AssignDriver(request.DriverId, dispatcherId, clock.UtcNow);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(order);
    }

    public async Task<OrderResponse> TransitionAsync(
        Guid id,
        Guid actorId,
        TransitionOrderRequest request,
        CancellationToken cancellationToken)
    {
        if (request.Status is not (OrderStatus.Accepted or OrderStatus.PickedUp or OrderStatus.Delivered))
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["status"] = ["Drivers can only mark an order Accepted, Picked Up, or Delivered."]
            });

        var order = await GetRequiredAsync(id, cancellationToken);
        if (order.AssignedDriverId != actorId)
            throw new ConflictException("Only the assigned driver can update this order.");

        order.TransitionTo(request.Status, actorId, clock.UtcNow, request.Note);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(order);
    }

    private async Task<Order> GetRequiredAsync(Guid id, CancellationToken cancellationToken) =>
        await orders.GetByIdAsync(id, cancellationToken)
        ?? throw new NotFoundException($"Order '{id}' was not found.");

    private static void ValidateCreate(CreateOrderRequest request)
    {
        var errors = new Dictionary<string, string[]>();
        if (string.IsNullOrWhiteSpace(request.IdempotencyKey) || request.IdempotencyKey.Length > 100)
            errors["idempotencyKey"] = ["Provide an idempotency key of 1 to 100 characters."];
        if (string.IsNullOrWhiteSpace(request.ContactName) || request.ContactName.Length > 100)
            errors["contactName"] = ["Contact name is required and must not exceed 100 characters."];
        if (string.IsNullOrWhiteSpace(request.PhoneNumber) || !EthiopianPhoneRegex().IsMatch(request.PhoneNumber.Trim()))
            errors["phoneNumber"] = ["Enter a valid Ethiopian phone number, for example +251911234567."];
        if (string.IsNullOrWhiteSpace(request.DeliveryAddress) || request.DeliveryAddress.Length > 500)
            errors["deliveryAddress"] = ["Delivery address is required and must not exceed 500 characters."];
        if (!Enum.IsDefined(request.PaymentMethod))
            errors["paymentMethod"] = ["Select a supported demonstration payment method."];
        if (request.Lines is null || request.Lines.Count == 0)
            errors["lines"] = ["Add at least one product."];
        else if (request.Lines.Any(line => line.Quantity is < 1 or > 50))
            errors["lines"] = ["Each product quantity must be between 1 and 50."];

        if (errors.Count > 0) throw new ValidationException(errors);
    }

    private static OrderSummaryResponse MapSummary(Order order) => new(
        order.Id,
        order.OrderNumber,
        order.ContactName,
        order.Status,
        order.Total,
        order.AssignedDriverId,
        order.CreatedAtUtc);

    private static OrderResponse Map(Order order) => new(
        order.Id,
        order.OrderNumber,
        order.CustomerId,
        order.AssignedDriverId,
        order.ContactName,
        order.PhoneNumber,
        order.DeliveryAddress,
        order.PaymentMethod,
        order.Status,
        order.Subtotal,
        order.DeliveryFee,
        order.Total,
        order.CreatedAtUtc,
        order.UpdatedAtUtc,
        order.Lines.Select(line => new OrderLineResponse(
            line.ProductId,
            line.ProductName,
            line.Unit,
            line.Quantity,
            line.UnitPrice,
            line.LineTotal)).ToList(),
        order.StatusHistory.OrderBy(item => item.ChangedAtUtc).Select(item => new StatusHistoryResponse(
            item.Status,
            item.ChangedByUserId,
            item.ChangedAtUtc,
            item.Note)).ToList());

    [GeneratedRegex(@"^(\+251|0)?9\d{8}$", RegexOptions.Compiled)]
    private static partial Regex EthiopianPhoneRegex();
}
