using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Drivers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize(Policy = "DispatcherOnly")]
[Route("api/v1/drivers")]
public sealed class DriversController(IDriverService drivers) : ControllerBase
{
    [HttpGet("available")]
    [ProducesResponseType<IReadOnlyList<AuthenticatedUser>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<AuthenticatedUser>>> GetAvailable(
        [FromQuery] Guid? forOrderId,
        CancellationToken cancellationToken) =>
        Ok(await drivers.GetAvailableAsync(forOrderId, cancellationToken));
}
