using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class PersistenceModelTests
{
    [Theory]
    [InlineData(typeof(Order), "Id")]
    [InlineData(typeof(OrderLine), "Id")]
    [InlineData(typeof(OrderStatusHistory), "Id")]
    [InlineData(typeof(DriverAssignment), "Id")]
    [InlineData(typeof(DriverLocation), "DriverId")]
    public void DomainAssignedIdentifiersAreNeverDatabaseGenerated(Type entityType, string propertyName)
    {
        var options = new DbContextOptionsBuilder<DeliveryDbContext>()
            .UseNpgsql("Host=127.0.0.1;Database=model_only")
            .Options;
        using var context = new DeliveryDbContext(options);

        var idProperty = context.Model.FindEntityType(entityType)?.FindProperty(propertyName);

        Assert.NotNull(idProperty);
        Assert.Equal(ValueGenerated.Never, idProperty.ValueGenerated);
    }
}
