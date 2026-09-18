namespace Creavers.Delivery.Application.Drivers;

public interface IDriverService
{
    Task<IReadOnlyList<DriverAccountResponse>> ListAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<DriverAccountResponse>> GetAvailableAsync(
        Guid? forOrderId,
        CancellationToken cancellationToken);
    Task<DriverAccountResponse> CreateAsync(
        CreateDriverRequest request,
        CancellationToken cancellationToken);
    Task<DriverAccountResponse> SetActiveAsync(
        Guid driverId,
        SetDriverStatusRequest request,
        CancellationToken cancellationToken);
}
