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
        string imageUrl,
        int stockQuantity = 0)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(price);
        ArgumentOutOfRangeException.ThrowIfNegative(stockQuantity);

        Id = id;
        CategoryId = categoryId;
        Name = name.Trim();
        Description = description.Trim();
        Unit = unit.Trim();
        Price = price;
        ImageUrl = imageUrl.Trim();
        StockQuantity = stockQuantity;
        IsActive = stockQuantity > 0;
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
    public int StockQuantity { get; private set; }

    public void UpdateDetails(
        Guid categoryId,
        string name,
        string description,
        string unit,
        decimal price,
        string imageUrl,
        int stockQuantity)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(price);
        ArgumentOutOfRangeException.ThrowIfNegative(stockQuantity);
        CategoryId = categoryId;
        Name = name.Trim();
        Description = description.Trim();
        Unit = unit.Trim();
        Price = price;
        ImageUrl = imageUrl.Trim();
        StockQuantity = stockQuantity;
        if (stockQuantity == 0) IsActive = false;
    }

    public void SetAvailability(bool isAvailable)
    {
        if (isAvailable && StockQuantity == 0)
            throw new InvalidOperationException("A product needs stock before it can be made available.");
        IsActive = isAvailable;
    }

    public void ReserveStock(int quantity)
    {
        if (quantity < 1 || quantity > StockQuantity)
            throw new InvalidOperationException($"Only {StockQuantity} unit(s) are currently available.");
        StockQuantity -= quantity;
        if (StockQuantity == 0) IsActive = false;
    }
}
