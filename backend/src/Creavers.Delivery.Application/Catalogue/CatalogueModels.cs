namespace Creavers.Delivery.Application.Catalogue;

public sealed record ProductResponse(
    Guid Id,
    string Name,
    string Description,
    string Unit,
    decimal Price,
    string ImageUrl,
    int StockQuantity);

public sealed record CategoryResponse(
    Guid Id,
    string Name,
    string Slug,
    IReadOnlyList<ProductResponse> Products);
