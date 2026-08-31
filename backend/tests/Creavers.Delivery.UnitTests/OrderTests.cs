using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Creavers.Delivery.Domain.Exceptions;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class OrderTests
{
    [Fact]
    public void CreateCalculatesServerSideTotals()
    {
        var customerId = Guid.NewGuid();
        var order = CreateOrder(customerId);

        Assert.Equal(250m, order.Subtotal);
        Assert.Equal(80m, order.DeliveryFee);
        Assert.Equal(330m, order.Total);
        Assert.Equal(OrderStatus.New, order.Status);
    }

    [Fact]
    public void TransitionRejectsSkippingRequiredStates()
    {
        var order = CreateOrder(Guid.NewGuid());

        var exception = Assert.Throws<DomainRuleException>(() =>
            order.TransitionTo(OrderStatus.Delivered, Guid.NewGuid(), DateTimeOffset.UtcNow));

        Assert.Contains("cannot move", exception.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void AssignDriverRecordsStatusAndAssignmentHistory()
    {
        var order = CreateOrder(Guid.NewGuid());
        var driverId = Guid.NewGuid();

        order.AssignDriver(driverId, Guid.NewGuid(), DateTimeOffset.UtcNow);

        Assert.Equal(OrderStatus.Assigned, order.Status);
        Assert.Equal(driverId, order.AssignedDriverId);
        Assert.Single(order.Assignments);
        Assert.Equal(2, order.StatusHistory.Count);
    }

    private static Order CreateOrder(Guid customerId) => Order.Create(
        Guid.NewGuid(),
        "CRV-TEST-001",
        customerId,
        "test-key",
        "Demo Customer",
        "+251911234567",
        "CMC, Addis Ababa",
        PaymentMethod.DemoCash,
        80m,
        [new OrderLine(Guid.NewGuid(), Guid.NewGuid(), "Coffee", "500 g", 2, 125m)],
        DateTimeOffset.UtcNow);
}
