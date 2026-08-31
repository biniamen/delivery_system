using Creavers.Delivery.Domain.Exceptions;

namespace Creavers.Delivery.Domain.Entities;

public sealed class DriverLocation
{
    private DriverLocation() { }

    public DriverLocation(
        Guid driverId,
        double latitude,
        double longitude,
        double accuracyMeters,
        double? headingDegrees,
        double? speedMetersPerSecond,
        DateTimeOffset capturedAtUtc,
        DateTimeOffset receivedAtUtc)
    {
        DriverId = driverId;
        Update(
            latitude,
            longitude,
            accuracyMeters,
            headingDegrees,
            speedMetersPerSecond,
            capturedAtUtc,
            receivedAtUtc);
    }

    public Guid DriverId { get; private set; }
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }
    public double AccuracyMeters { get; private set; }
    public double? HeadingDegrees { get; private set; }
    public double? SpeedMetersPerSecond { get; private set; }
    public DateTimeOffset CapturedAtUtc { get; private set; }
    public DateTimeOffset ReceivedAtUtc { get; private set; }

    public void Update(
        double latitude,
        double longitude,
        double accuracyMeters,
        double? headingDegrees,
        double? speedMetersPerSecond,
        DateTimeOffset capturedAtUtc,
        DateTimeOffset receivedAtUtc)
    {
        if (latitude is < -90 or > 90) throw new DomainRuleException("Latitude must be between -90 and 90.");
        if (longitude is < -180 or > 180) throw new DomainRuleException("Longitude must be between -180 and 180.");
        if (accuracyMeters is < 0 or > 2_000) throw new DomainRuleException("Location accuracy must be between 0 and 2,000 metres.");
        if (headingDegrees is < 0 or >= 360) throw new DomainRuleException("Heading must be at least 0 and less than 360 degrees.");
        if (speedMetersPerSecond is < 0 or > 100) throw new DomainRuleException("Speed must be between 0 and 100 metres per second.");
        if (CapturedAtUtc != default && capturedAtUtc < CapturedAtUtc)
            throw new DomainRuleException("A location update cannot be older than the current driver position.");

        Latitude = latitude;
        Longitude = longitude;
        AccuracyMeters = accuracyMeters;
        HeadingDegrees = headingDegrees;
        SpeedMetersPerSecond = speedMetersPerSecond;
        CapturedAtUtc = capturedAtUtc;
        ReceivedAtUtc = receivedAtUtc;
    }
}
