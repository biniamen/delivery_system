using System.Security.Claims;
using Creavers.Delivery.Api.Extensions;
using Creavers.Delivery.Application.Locations;
using Creavers.Delivery.Application.Maps;
using Creavers.Delivery.Application.Orders;
using Creavers.Delivery.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Caching.Memory;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize]
[EnableRateLimiting("maps")]
[Route("api/v1/maps")]
public sealed class MapsController(
    IMapPlatformService maps,
    IOrderService orders,
    IDriverLocationService locations,
    IMemoryCache cache) : ControllerBase
{
    [HttpGet("browser-configuration")]
    [Authorize(Policy = "DispatcherOnly")]
    [ProducesResponseType<MapsClientConfigurationResponse>(StatusCodes.Status200OK)]
    public ActionResult<MapsClientConfigurationResponse> BrowserConfiguration() =>
        Ok(maps.GetClientConfiguration());

    [HttpGet("places/autocomplete")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType<IReadOnlyList<PlaceSuggestionResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<PlaceSuggestionResponse>>> Autocomplete(
        [FromQuery] string query,
        [FromQuery] string sessionToken,
        CancellationToken cancellationToken) =>
        Ok(await maps.AutocompleteAsync(query, sessionToken, cancellationToken));

    [HttpGet("places/{placeId}")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType<MapLocationResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<ActionResult<MapLocationResponse>> PlaceDetails(
        string placeId,
        [FromQuery] string sessionToken,
        CancellationToken cancellationToken)
    {
        var result = await maps.GetPlaceAsync(placeId, sessionToken, cancellationToken);
        return result is null ? NoContent() : Ok(result);
    }

    [HttpGet("geocode")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType<MapLocationResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<ActionResult<MapLocationResponse>> Geocode(
        [FromQuery] string address,
        CancellationToken cancellationToken)
    {
        var result = await maps.GeocodeAsync(address, cancellationToken);
        return result is null ? NoContent() : Ok(result);
    }

    [HttpGet("reverse-geocode")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType<MapLocationResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<ActionResult<MapLocationResponse>> ReverseGeocode(
        [FromQuery] double latitude,
        [FromQuery] double longitude,
        CancellationToken cancellationToken)
    {
        var result = await maps.ReverseGeocodeAsync(latitude, longitude, cancellationToken);
        return result is null ? NoContent() : Ok(result);
    }

    [HttpGet("orders/{orderId:guid}/route")]
    [ProducesResponseType<DeliveryRouteResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DeliveryRouteResponse>> DeliveryRoute(
        Guid orderId,
        CancellationToken cancellationToken)
    {
        var order = await orders.GetAsync(orderId, cancellationToken);
        if (!CanView(order)) return Forbid();
        if (!maps.GetClientConfiguration().GoogleWebServicesEnabled) return NoContent();
        if (order.AssignedDriverId is not { } driverId ||
            order.DeliveryLatitude is not { } destinationLatitude ||
            order.DeliveryLongitude is not { } destinationLongitude)
            return NoContent();

        var driver = await locations.GetDriverAsync(driverId, cancellationToken);
        if (driver?.Latitude is not { } originLatitude || driver.Longitude is not { } originLongitude)
            return NoContent();

        var cacheKey = FormattableString.Invariant(
            $"route:{orderId}:{Math.Round(originLatitude, 4)}:{Math.Round(originLongitude, 4)}");
        var route = await cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30);
            return await maps.ComputeRouteAsync(
                orderId,
                originLatitude,
                originLongitude,
                destinationLatitude,
                destinationLongitude,
                cancellationToken);
        });

        return route is null ? NoContent() : Ok(route);
    }

    private bool CanView(OrderResponse order)
    {
        var userId = User.GetRequiredUserId();
        return User.FindFirstValue(ClaimTypes.Role) switch
        {
            nameof(UserRole.Dispatcher) => true,
            nameof(UserRole.Customer) => order.CustomerId == userId,
            nameof(UserRole.Driver) => order.AssignedDriverId == userId,
            _ => false
        };
    }
}
