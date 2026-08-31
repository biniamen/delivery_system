namespace Creavers.Delivery.Application.Locations;

public interface IDriverLocationService
{
    Task<DriverLocationResponse> RecordAsync(
        Guid driverId,
        UpdateDriverLocationRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<DriverLocationResponse>> ListDriversAsync(CancellationToken cancellationToken);

    Task<DriverLocationResponse?> GetDriverAsync(Guid driverId, CancellationToken cancellationToken);
}
