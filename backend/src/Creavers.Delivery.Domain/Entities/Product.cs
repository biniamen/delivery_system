namespace Creavers.Delivery.Domain.Entities;

public sealed class Product
{
    private Product() { }

    public Product(
        Guid id,
        Guid categoryId,
        string name,
        string description,
        string unit,
        decimal price,
        string imageUrl)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(price);

        Id = id;
        CategoryId = categoryId;
        Name = name.Trim();
        Description = description.Trim();
        Unit = unit.Trim();
        Price = price;
        ImageUrl = imageUrl.Trim();
    }

    public Guid Id { get; private set; }
    public Guid CategoryId { get; private set; }
    public Category Category { get; private set; } = null!;
    public string Name { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public string Unit { get; private set; } = string.Empty;
    public decimal Price { get; private set; }
    public string ImageUrl { get; private set; } = string.Empty;
    public bool IsActive { get; private set; } = true;
}
