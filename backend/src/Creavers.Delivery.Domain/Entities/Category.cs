namespace Creavers.Delivery.Domain.Entities;

public sealed class Category
{
    private Category() { }

    public Category(Guid id, string name, string slug, int displayOrder)
    {
        Id = id;
        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        DisplayOrder = displayOrder;
    }

    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Slug { get; private set; } = string.Empty;
    public int DisplayOrder { get; private set; }
    public ICollection<Product> Products { get; private set; } = new List<Product>();
}

