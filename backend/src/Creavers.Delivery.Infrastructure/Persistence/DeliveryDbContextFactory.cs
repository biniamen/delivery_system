using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Creavers.Delivery.Infrastructure.Persistence;

public sealed class DeliveryDbContextFactory : IDesignTimeDbContextFactory<DeliveryDbContext>
{
    public DeliveryDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__Postgres");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Set ConnectionStrings__Postgres before using EF Core tools.");
        var options = new DbContextOptionsBuilder<DeliveryDbContext>()
            .UseNpgsql(connectionString)
            .Options;
        return new DeliveryDbContext(options);
    }
}
