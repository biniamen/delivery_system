using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Creavers.Delivery.Infrastructure.Persistence.Configurations;

public sealed class DriverLocationConfiguration : IEntityTypeConfiguration<DriverLocation>
{
    public void Configure(EntityTypeBuilder<DriverLocation> builder)
    {
        builder.ToTable("driver_locations");
        builder.HasKey(location => location.DriverId);
        builder.Property(location => location.DriverId).ValueGeneratedNever();
        builder.Property(location => location.Latitude).IsRequired();
        builder.Property(location => location.Longitude).IsRequired();
        builder.Property(location => location.AccuracyMeters).IsRequired();
        builder.HasIndex(location => location.ReceivedAtUtc);
        builder
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(location => location.DriverId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
