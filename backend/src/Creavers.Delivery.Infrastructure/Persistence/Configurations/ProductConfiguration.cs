using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Creavers.Delivery.Infrastructure.Persistence.Configurations;

public sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("products");
        builder.HasKey(product => product.Id);
        builder.Property(product => product.Id).ValueGeneratedNever();
        builder.Property(product => product.Name).HasMaxLength(150).IsRequired();
        builder.Property(product => product.Description).HasMaxLength(500).IsRequired();
        builder.Property(product => product.Unit).HasMaxLength(50).IsRequired();
        builder.Property(product => product.Price).HasPrecision(12, 2).IsRequired();
        builder.Property(product => product.ImageUrl).HasMaxLength(500).IsRequired();
        builder.Property(product => product.StockQuantity).IsRequired();
        builder.HasIndex(product => new { product.CategoryId, product.Name }).IsUnique();
    }
}
