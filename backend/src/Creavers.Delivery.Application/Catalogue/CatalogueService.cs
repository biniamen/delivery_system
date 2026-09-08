using Creavers.Delivery.Application.Repositories;

namespace Creavers.Delivery.Application.Catalogue;

public sealed class CatalogueService(ICatalogueRepository catalogue) : ICatalogueService
{
    public async Task<IReadOnlyList<CategoryResponse>> GetAsync(CancellationToken cancellationToken)
    {
        var categories = await catalogue.GetCatalogueAsync(cancellationToken);
        return categories
            .OrderBy(category => category.DisplayOrder)
            .Select(category => new CategoryResponse(
                category.Id,
                category.Name,
                category.Slug,
                category.Products
                    .Where(product => product.IsActive && product.StockQuantity > 0)
                    .OrderBy(product => product.Name)
                    .Select(product => new ProductResponse(
                        product.Id,
                        product.Name,
                        product.Description,
                        product.Unit,
                        product.Price,
                        product.ImageUrl,
                        product.StockQuantity))
                    .ToList()))
            .ToList();
    }

    public async Task<ProductResponse?> GetProductByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var product = await catalogue.GetProductByIdAsync(id, cancellationToken);
        // if (product is null)
            return product is null
            ? null
            : new ProductResponse(
                product.Id,
                product.Name,
                product.Description,
                product.Unit,
                product.Price,
                product.ImageUrl);
    }
}
