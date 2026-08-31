using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Creavers.Delivery.Infrastructure.Persistence.Repositories;

public sealed class CatalogueRepository(DeliveryDbContext dbContext) : ICatalogueRepository
{
    public async Task<IReadOnlyList<Category>> GetCatalogueAsync(CancellationToken cancellationToken) =>
        await dbContext.Categories
            .AsNoTracking()
            .Include(category => category.Products)
            .OrderBy(category => category.DisplayOrder)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyDictionary<Guid, Product>> GetActiveProductsAsync(
        IEnumerable<Guid> ids,
        CancellationToken cancellationToken)
    {
        var distinctIds = ids.Distinct().ToArray();
        return await dbContext.Products
            .AsNoTracking()
            .Where(product => distinctIds.Contains(product.Id) && product.IsActive)
            .ToDictionaryAsync(product => product.Id, cancellationToken);
    }
}

