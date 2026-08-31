namespace Creavers.Delivery.Application.Catalogue;

public interface ICatalogueService
{
    Task<IReadOnlyList<CategoryResponse>> GetAsync(CancellationToken cancellationToken);
}

