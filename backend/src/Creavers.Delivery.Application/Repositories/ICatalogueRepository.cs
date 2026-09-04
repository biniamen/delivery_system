using Creavers.Delivery.Domain.Entities;

namespace Creavers.Delivery.Application.Repositories;

public interface ICatalogueRepository
{
    Task<IReadOnlyList<Category>> GetCatalogueAsync(CancellationToken cancellationToken);
    Task<IReadOnlyDictionary<Guid, Product>> GetActiveProductsAsync(IEnumerable<Guid> ids, CancellationToken cancellationToken);
    Task<Product?> GetProductAsync(Guid id, CancellationToken cancellationToken);
    Task<Category?> GetCategoryAsync(Guid id, CancellationToken cancellationToken);
    Task AddProductAsync(Product product, CancellationToken cancellationToken);
}
