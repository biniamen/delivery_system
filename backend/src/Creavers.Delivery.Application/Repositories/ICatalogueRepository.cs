using Creavers.Delivery.Domain.Entities;

namespace Creavers.Delivery.Application.Repositories;

public interface ICatalogueRepository
{
    Task<IReadOnlyList<Category>> GetCatalogueAsync(CancellationToken cancellationToken);
    Task<IReadOnlyDictionary<Guid, Product>> GetActiveProductsAsync(IEnumerable<Guid> ids, CancellationToken cancellationToken);
}

