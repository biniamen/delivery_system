namespace Creavers.Delivery.Application.Locations;

public enum LocationFreshness
{
    Unavailable,
    Live,
    Recent,
    Stale
}

public sealed record UpdateDriverLocationRequest(
    double Latitude,
    double Longitude,
    double AccuracyMeters,
    double? HeadingDegrees,
    double? SpeedMetersPerSecond,
    DateTimeOffset CapturedAtUtc);

public sealed record DriverLocationResponse(
    Guid DriverId,
    string DisplayName,
    LocationFreshness Freshness,
    double? Latitude,
    double? Longitude,
    double? AccuracyMeters,
    double? HeadingDegrees,
    double? SpeedMetersPerSecond,
    DateTimeOffset? CapturedAtUtc,
    DateTimeOffset? ReceivedAtUtc);
