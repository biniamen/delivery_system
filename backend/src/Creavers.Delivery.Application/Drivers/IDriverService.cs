using Creavers.Delivery.Application.Authentication;

namespace Creavers.Delivery.Application.Drivers;

public interface IDriverService
{
    Task<IReadOnlyList<AuthenticatedUser>> GetAvailableAsync(
        Guid? forOrderId,
        CancellationToken cancellationToken);
}
