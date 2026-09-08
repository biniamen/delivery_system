namespace Creavers.Delivery.Application.Locations;

using Creavers.Delivery.Domain.Enums;

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

public sealed record DriverLoadOrderResponse(
    Guid OrderId,
    string OrderNumber,
    OrderStatus Status,
    int ItemCount,
    decimal Total,
    string DeliveryAddress,
    double? DeliveryLatitude,
    double? DeliveryLongitude);

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
    DateTimeOffset? ReceivedAtUtc,
    int ActiveOrderCount,
    int ActiveItemCount,
    IReadOnlyList<DriverLoadOrderResponse> ActiveOrders);
