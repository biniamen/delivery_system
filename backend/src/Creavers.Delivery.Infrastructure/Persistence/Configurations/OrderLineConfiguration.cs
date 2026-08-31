using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Creavers.Delivery.Infrastructure.Persistence.Configurations;

public sealed class OrderLineConfiguration : IEntityTypeConfiguration<OrderLine>
{
    public void Configure(EntityTypeBuilder<OrderLine> builder)
    {
        builder.ToTable("order_lines");
        builder.HasKey(line => line.Id);
        builder.Property(line => line.Id).ValueGeneratedNever();
        builder.Property(line => line.ProductName).HasMaxLength(150).IsRequired();
        builder.Property(line => line.Unit).HasMaxLength(50).IsRequired();
        builder.Property(line => line.UnitPrice).HasPrecision(12, 2);
        builder.Property(line => line.LineTotal).HasPrecision(12, 2);
    }
}
