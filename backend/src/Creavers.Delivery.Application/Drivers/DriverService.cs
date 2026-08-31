using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Drivers;

public sealed class DriverService(IUserRepository users) : IDriverService
{
    public async Task<IReadOnlyList<AuthenticatedUser>> GetAvailableAsync(CancellationToken cancellationToken)
    {
        var drivers = await users.GetActiveByRoleAsync(UserRole.Driver, cancellationToken);
        return drivers
            .Select(driver => new AuthenticatedUser(driver.Id, driver.Email, driver.DisplayName, driver.Role))
            .ToList();
    }
}

