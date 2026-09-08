using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Creavers.Delivery.Infrastructure.Persistence.Configurations;

public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("orders");
        builder.HasKey(order => order.Id);
        builder.Property(order => order.Id).ValueGeneratedNever();
        builder.Property(order => order.OrderNumber).HasMaxLength(40).IsRequired();
        builder.HasIndex(order => order.OrderNumber).IsUnique();
        builder.Property(order => order.IdempotencyKey).HasMaxLength(100).IsRequired();
        builder.HasIndex(order => new { order.CustomerId, order.IdempotencyKey }).IsUnique();
        builder.Property(order => order.ContactName).HasMaxLength(100).IsRequired();
        builder.Property(order => order.PhoneNumber).HasMaxLength(30).IsRequired();
        builder.Property(order => order.DeliveryAddress).HasMaxLength(500).IsRequired();
        builder.Property(order => order.DeliveryLatitude);
        builder.Property(order => order.DeliveryLongitude);
        builder.Property(order => order.PaymentMethod).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(order => order.Status).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(order => order.Subtotal).HasPrecision(12, 2);
        builder.Property(order => order.DeliveryFee).HasPrecision(12, 2);
        builder.Property(order => order.Total).HasPrecision(12, 2);

        builder.HasMany(order => order.Lines)
            .WithOne()
            .HasForeignKey(line => line.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(order => order.StatusHistory)
            .WithOne()
            .HasForeignKey(history => history.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(order => order.Assignments)
            .WithOne()
            .HasForeignKey(assignment => assignment.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
