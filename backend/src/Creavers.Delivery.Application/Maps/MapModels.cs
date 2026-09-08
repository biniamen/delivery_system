namespace Creavers.Delivery.Application.Maps;

public sealed record MapsClientConfigurationResponse(
    bool GoogleMapsEnabled,
    bool GoogleWebServicesEnabled,
    string Provider,
    string? BrowserApiKey,
    string MapId);

public sealed record PlaceSuggestionResponse(
    string PlaceId,
    string MainText,
    string SecondaryText,
    string FullText);

public sealed record MapLocationResponse(
    string? PlaceId,
    string FormattedAddress,
    double Latitude,
    double Longitude);

public sealed record RoutePointResponse(double Latitude, double Longitude);

public sealed record DeliveryRouteResponse(
    Guid OrderId,
    double OriginLatitude,
    double OriginLongitude,
    double DestinationLatitude,
    double DestinationLongitude,
    int DistanceMeters,
    int DurationSeconds,
    string DistanceText,
    string DurationText,
    IReadOnlyList<RoutePointResponse> Path,
    string Provider,
    DateTimeOffset CalculatedAtUtc);
