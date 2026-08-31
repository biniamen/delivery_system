using Creavers.Delivery.Domain.Entities;

namespace Creavers.Delivery.Application.Repositories;

public interface IDriverLocationRepository
{
    Task<DriverLocation?> GetAsync(Guid driverId, CancellationToken cancellationToken);
    Task<IReadOnlyList<DriverLocation>> ListAsync(IReadOnlyCollection<Guid> driverIds, CancellationToken cancellationToken);
    Task AddAsync(DriverLocation location, CancellationToken cancellationToken);
}
