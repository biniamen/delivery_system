using Creavers.Delivery.Domain.Enums;
using Creavers.Delivery.Domain.Exceptions;

namespace Creavers.Delivery.Domain.Entities;

public sealed class Order
{
    private static readonly Dictionary<OrderStatus, OrderStatus[]> AllowedTransitions =
        new Dictionary<OrderStatus, OrderStatus[]>
        {
            [OrderStatus.New] = [OrderStatus.Assigned, OrderStatus.Cancelled],
            [OrderStatus.Assigned] = [OrderStatus.Accepted, OrderStatus.Cancelled],
            [OrderStatus.Accepted] = [OrderStatus.PickedUp],
            [OrderStatus.PickedUp] = [OrderStatus.Delivered]
        };

    private Order() { }

    public static Order Create(
        Guid id,
        string orderNumber,
        Guid customerId,
        string idempotencyKey,
        string contactName,
        string phoneNumber,
        string deliveryAddress,
        PaymentMethod paymentMethod,
        decimal deliveryFee,
        IEnumerable<OrderLine> lines,
        DateTimeOffset createdAtUtc)
    {
        var materializedLines = lines.ToList();
        if (materializedLines.Count == 0) throw new DomainRuleException("An order must contain at least one product.");
        if (deliveryFee < 0) throw new DomainRuleException("Delivery fee cannot be negative.");

        var subtotal = materializedLines.Sum(line => line.LineTotal);
        var order = new Order
        {
            Id = id,
            OrderNumber = orderNumber,
            CustomerId = customerId,
            IdempotencyKey = idempotencyKey.Trim(),
            ContactName = contactName.Trim(),
            PhoneNumber = phoneNumber.Trim(),
            DeliveryAddress = deliveryAddress.Trim(),
            PaymentMethod = paymentMethod,
            Status = OrderStatus.New,
            Subtotal = subtotal,
            DeliveryFee = deliveryFee,
            Total = subtotal + deliveryFee,
            CreatedAtUtc = createdAtUtc,
            UpdatedAtUtc = createdAtUtc
        };

        foreach (var line in materializedLines) order.Lines.Add(line);
        order.StatusHistory.Add(new OrderStatusHistory(Guid.NewGuid(), OrderStatus.New, customerId, createdAtUtc, "Order submitted"));
        return order;
    }

    public Guid Id { get; private set; }
    public string OrderNumber { get; private set; } = string.Empty;
    public Guid CustomerId { get; private set; }
    public Guid? AssignedDriverId { get; private set; }
    public string IdempotencyKey { get; private set; } = string.Empty;
    public string ContactName { get; private set; } = string.Empty;
    public string PhoneNumber { get; private set; } = string.Empty;
    public string DeliveryAddress { get; private set; } = string.Empty;
    public PaymentMethod PaymentMethod { get; private set; }
    public OrderStatus Status { get; private set; }
    public decimal Subtotal { get; private set; }
    public decimal DeliveryFee { get; private set; }
    public decimal Total { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; }
    public DateTimeOffset UpdatedAtUtc { get; private set; }
    public ICollection<OrderLine> Lines { get; private set; } = new List<OrderLine>();
    public ICollection<OrderStatusHistory> StatusHistory { get; private set; } = new List<OrderStatusHistory>();
    public ICollection<DriverAssignment> Assignments { get; private set; } = new List<DriverAssignment>();

    public void AssignDriver(Guid driverId, Guid dispatcherId, DateTimeOffset assignedAtUtc)
    {
        if (Status is not (OrderStatus.New or OrderStatus.Assigned))
            throw new DomainRuleException("An order can only be assigned or reassigned before the driver accepts it.");

        AssignedDriverId = driverId;
        Status = OrderStatus.Assigned;
        UpdatedAtUtc = assignedAtUtc;
        Assignments.Add(new DriverAssignment(Guid.NewGuid(), driverId, dispatcherId, assignedAtUtc));
        StatusHistory.Add(new OrderStatusHistory(Guid.NewGuid(), Status, dispatcherId, assignedAtUtc, "Driver assigned"));
    }

    public void TransitionTo(OrderStatus nextStatus, Guid actorUserId, DateTimeOffset changedAtUtc, string? note = null)
    {
        if (!AllowedTransitions.TryGetValue(Status, out var candidates) || !candidates.Contains(nextStatus))
            throw new DomainRuleException($"Order cannot move from {Status} to {nextStatus}.");

        Status = nextStatus;
        UpdatedAtUtc = changedAtUtc;
        StatusHistory.Add(new OrderStatusHistory(Guid.NewGuid(), nextStatus, actorUserId, changedAtUtc, note));
    }
}
