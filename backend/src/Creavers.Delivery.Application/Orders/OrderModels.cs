using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Orders;

public sealed record CreateOrderLineRequest(Guid ProductId, int Quantity);

public sealed record CreateOrderRequest(
    string IdempotencyKey,
    string ContactName,
    string PhoneNumber,
    string DeliveryAddress,
    double DeliveryLatitude,
    double DeliveryLongitude,
    PaymentMethod PaymentMethod,
    IReadOnlyList<CreateOrderLineRequest> Lines);

public sealed record AssignDriverRequest(Guid DriverId);

public sealed record TransitionOrderRequest(OrderStatus Status, string? Note);

public sealed record OrderLineResponse(
    Guid ProductId,
    string ProductName,
    string Unit,
    int Quantity,
    decimal UnitPrice,
    decimal LineTotal);

public sealed record StatusHistoryResponse(
    OrderStatus Status,
    Guid ChangedByUserId,
    DateTimeOffset ChangedAtUtc,
    string? Note);

public sealed record OrderSummaryResponse(
    Guid Id,
    string OrderNumber,
    string ContactName,
    OrderStatus Status,
    decimal Total,
    Guid? AssignedDriverId,
    DateTimeOffset CreatedAtUtc);

public sealed record OrderResponse(
    Guid Id,
    string OrderNumber,
    Guid CustomerId,
    Guid? AssignedDriverId,
    string ContactName,
    string PhoneNumber,
    string DeliveryAddress,
    double? DeliveryLatitude,
    double? DeliveryLongitude,
    PaymentMethod PaymentMethod,
    OrderStatus Status,
    decimal Subtotal,
    decimal DeliveryFee,
    decimal Total,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset UpdatedAtUtc,
    IReadOnlyList<OrderLineResponse> Lines,
    IReadOnlyList<StatusHistoryResponse> StatusHistory);
