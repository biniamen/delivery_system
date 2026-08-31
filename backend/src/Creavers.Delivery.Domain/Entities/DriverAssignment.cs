namespace Creavers.Delivery.Domain.Entities;

public sealed class DriverAssignment
{
    private DriverAssignment() { }

    public DriverAssignment(Guid id, Guid driverId, Guid assignedByUserId, DateTimeOffset assignedAtUtc)
    {
        Id = id;
        DriverId = driverId;
        AssignedByUserId = assignedByUserId;
        AssignedAtUtc = assignedAtUtc;
    }

    public Guid Id { get; private set; }
    public Guid OrderId { get; private set; }
    public Guid DriverId { get; private set; }
    public Guid AssignedByUserId { get; private set; }
    public DateTimeOffset AssignedAtUtc { get; private set; }
}

