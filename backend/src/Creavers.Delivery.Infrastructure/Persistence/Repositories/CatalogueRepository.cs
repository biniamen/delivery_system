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
            .Where(product => distinctIds.Contains(product.Id) && product.IsActive && product.StockQuantity > 0)
            .ToDictionaryAsync(product => product.Id, cancellationToken);
    }

    public Task<Product?> GetProductAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Products.SingleOrDefaultAsync(product => product.Id == id, cancellationToken);

    public Task<Category?> GetCategoryAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Categories.AsNoTracking().SingleOrDefaultAsync(category => category.Id == id, cancellationToken);

    public Task AddProductAsync(Product product, CancellationToken cancellationToken) =>
        dbContext.Products.AddAsync(product, cancellationToken).AsTask();
}
