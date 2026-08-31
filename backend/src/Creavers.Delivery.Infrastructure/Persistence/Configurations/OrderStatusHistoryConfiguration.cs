using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Creavers.Delivery.Infrastructure.Persistence.Configurations;

public sealed class OrderStatusHistoryConfiguration : IEntityTypeConfiguration<OrderStatusHistory>
{
    public void Configure(EntityTypeBuilder<OrderStatusHistory> builder)
    {
        builder.ToTable("order_status_history");
        builder.HasKey(history => history.Id);
        builder.Property(history => history.Id).ValueGeneratedNever();
        builder.Property(history => history.Status).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(history => history.Note).HasMaxLength(500);
        builder.HasIndex(history => new { history.OrderId, history.ChangedAtUtc });
    }
}
