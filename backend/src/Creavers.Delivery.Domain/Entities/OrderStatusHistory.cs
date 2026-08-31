using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Domain.Entities;

public sealed class OrderStatusHistory
{
    private OrderStatusHistory() { }

    public OrderStatusHistory(Guid id, OrderStatus status, Guid changedByUserId, DateTimeOffset changedAtUtc, string? note)
    {
        Id = id;
        Status = status;
        ChangedByUserId = changedByUserId;
        ChangedAtUtc = changedAtUtc;
        Note = note?.Trim();
    }

    public Guid Id { get; private set; }
    public Guid OrderId { get; private set; }
    public OrderStatus Status { get; private set; }
    public Guid ChangedByUserId { get; private set; }
    public DateTimeOffset ChangedAtUtc { get; private set; }
    public string? Note { get; private set; }
}

