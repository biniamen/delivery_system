using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Creavers.Delivery.Infrastructure.Persistence.Repositories;

public sealed class DriverLocationRepository(DeliveryDbContext dbContext) : IDriverLocationRepository
{
    public Task<DriverLocation?> GetAsync(Guid driverId, CancellationToken cancellationToken) =>
        dbContext.DriverLocations.SingleOrDefaultAsync(location => location.DriverId == driverId, cancellationToken);

    public async Task<IReadOnlyList<DriverLocation>> ListAsync(
        IReadOnlyCollection<Guid> driverIds,
        CancellationToken cancellationToken) =>
        await dbContext.DriverLocations
            .AsNoTracking()
            .Where(location => driverIds.Contains(location.DriverId))
            .ToListAsync(cancellationToken);

    public Task AddAsync(DriverLocation location, CancellationToken cancellationToken) =>
        dbContext.DriverLocations.AddAsync(location, cancellationToken).AsTask();
}
