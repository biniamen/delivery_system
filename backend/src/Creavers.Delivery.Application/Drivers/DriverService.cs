using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Drivers;

public sealed class DriverService(
    IUserRepository users,
    IOrderRepository orders) : IDriverService
{
    public async Task<IReadOnlyList<AuthenticatedUser>> GetAvailableAsync(
        Guid? forOrderId,
        CancellationToken cancellationToken)
    {
        var drivers = await users.GetActiveByRoleAsync(UserRole.Driver, cancellationToken);
        if (drivers.Count == 0) return [];

        var activeOrders = await orders.ListActiveByDriversAsync(
            drivers.Select(driver => driver.Id).ToArray(),
            cancellationToken);
        var unavailableDriverIds = activeOrders
            .Where(order => !forOrderId.HasValue || order.Id != forOrderId.Value)
            .Select(order => order.AssignedDriverId)
            .OfType<Guid>()
            .ToHashSet();

        return drivers
            .Where(driver => !unavailableDriverIds.Contains(driver.Id))
            .Select(driver => new AuthenticatedUser(driver.Id, driver.Email, driver.DisplayName, driver.Role))
            .ToList();
    }
}
