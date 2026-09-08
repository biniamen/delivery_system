namespace Creavers.Delivery.Application.Maps;

public interface IMapPlatformService
{
    MapsClientConfigurationResponse GetClientConfiguration();

    Task<IReadOnlyList<PlaceSuggestionResponse>> AutocompleteAsync(
        string query,
        string sessionToken,
        CancellationToken cancellationToken);

    Task<MapLocationResponse?> GetPlaceAsync(
        string placeId,
        string sessionToken,
        CancellationToken cancellationToken);

    Task<MapLocationResponse?> GeocodeAsync(string address, CancellationToken cancellationToken);

    Task<MapLocationResponse?> ReverseGeocodeAsync(
        double latitude,
        double longitude,
        CancellationToken cancellationToken);

    Task<DeliveryRouteResponse> ComputeRouteAsync(
        Guid orderId,
        double originLatitude,
        double originLongitude,
        double destinationLatitude,
        double destinationLongitude,
        CancellationToken cancellationToken);
}
