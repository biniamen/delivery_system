namespace Creavers.Delivery.Application.Catalogue;

public sealed record AdminCategoryResponse(Guid Id, string Name, string Slug);

public sealed record AdminProductResponse(
    Guid Id,
    Guid CategoryId,
    string CategoryName,
    string Name,
    string Description,
    string Unit,
    decimal Price,
    string ImageUrl,
    int StockQuantity,
    bool IsAvailable);

public sealed record AdminCatalogueResponse(
    IReadOnlyList<AdminCategoryResponse> Categories,
    IReadOnlyList<AdminProductResponse> Products);

public sealed record SaveProductRequest(
    Guid CategoryId,
    string Name,
    string Description,
    string Unit,
    decimal Price,
    string ImageUrl,
    int StockQuantity,
    bool IsAvailable);

public sealed record SetProductAvailabilityRequest(bool IsAvailable);
