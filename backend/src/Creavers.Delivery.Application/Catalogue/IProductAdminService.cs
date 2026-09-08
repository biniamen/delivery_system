namespace Creavers.Delivery.Application.Catalogue;

public interface IProductAdminService
{
    Task<AdminCatalogueResponse> GetAsync(CancellationToken cancellationToken);
    Task<AdminProductResponse> CreateAsync(SaveProductRequest request, CancellationToken cancellationToken);
    Task<AdminProductResponse> UpdateAsync(Guid productId, SaveProductRequest request, CancellationToken cancellationToken);
    Task<AdminProductResponse> SetAvailabilityAsync(
        Guid productId,
        SetProductAvailabilityRequest request,
        CancellationToken cancellationToken);
}
