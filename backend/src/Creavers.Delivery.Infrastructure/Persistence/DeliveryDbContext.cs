using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Creavers.Delivery.Infrastructure.Persistence;

public sealed class DeliveryDbContext(DbContextOptions<DeliveryDbContext> options)
    : DbContext(options), IUnitOfWork
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderLine> OrderLines => Set<OrderLine>();
    public DbSet<OrderStatusHistory> OrderStatusHistory => Set<OrderStatusHistory>();
    public DbSet<DriverAssignment> DriverAssignments => Set<DriverAssignment>();
    public DbSet<DriverLocation> DriverLocations => Set<DriverLocation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder) =>
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(DeliveryDbContext).Assembly);
}
