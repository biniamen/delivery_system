using System.Security.Claims;
using Creavers.Delivery.Api.Extensions;
using Creavers.Delivery.Application.Locations;
using Creavers.Delivery.Application.Orders;
using Creavers.Delivery.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/driver-locations")]
public sealed class DriverLocationsController(
    IDriverLocationService locations,
    IOrderService orders) : ControllerBase
{
    [HttpPost("me")]
    [Authorize(Policy = "DriverOnly")]
    [EnableRateLimiting("driver-location")]
    [ProducesResponseType<DriverLocationResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DriverLocationResponse>> Record(
        UpdateDriverLocationRequest request,
        CancellationToken cancellationToken) =>
        Ok(await locations.RecordAsync(User.GetRequiredUserId(), request, cancellationToken));

    [HttpGet("live")]
    [Authorize(Policy = "DispatcherOnly")]
    [ProducesResponseType<IReadOnlyList<DriverLocationResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<DriverLocationResponse>>> ListLive(CancellationToken cancellationToken) =>
        Ok(await locations.ListDriversAsync(cancellationToken));

    [HttpGet("orders/{orderId:guid}")]
    [ProducesResponseType<DriverLocationResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DriverLocationResponse>> GetForOrder(
        Guid orderId,
        CancellationToken cancellationToken)
    {
        var order = await orders.GetAsync(orderId, cancellationToken);
        var userId = User.GetRequiredUserId();
        var role = User.FindFirstValue(ClaimTypes.Role);
        var canView = role == UserRole.Dispatcher.ToString()
            || (role == UserRole.Customer.ToString() && order.CustomerId == userId)
            || (role == UserRole.Driver.ToString() && order.AssignedDriverId == userId);

        if (!canView) return Forbid();
        if (order.AssignedDriverId is not { } driverId) return NoContent();

        var location = await locations.GetDriverAsync(driverId, cancellationToken);
        return location is null ? NoContent() : Ok(location);
    }
}
