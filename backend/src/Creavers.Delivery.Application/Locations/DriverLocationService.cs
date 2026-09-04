using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Locations;

public sealed class DriverLocationService(
    IDriverLocationRepository locations,
    IUserRepository users,
    IOrderRepository orders,
    IUnitOfWork unitOfWork,
    IClock clock) : IDriverLocationService
{
    private static readonly TimeSpan MaximumLocationAge = TimeSpan.FromHours(24);
    private static readonly TimeSpan MaximumClockSkew = TimeSpan.FromMinutes(2);

    public async Task<DriverLocationResponse> RecordAsync(
        Guid driverId,
        UpdateDriverLocationRequest request,
        CancellationToken cancellationToken)
    {
        Validate(request);

        var driver = await users.GetByIdAsync(driverId, cancellationToken);
        if (driver is null || !driver.IsActive || driver.Role != UserRole.Driver)
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["driverId"] = ["An active driver account is required."]
            });

        var now = clock.UtcNow;
        if (request.CapturedAtUtc < now - MaximumLocationAge || request.CapturedAtUtc > now + MaximumClockSkew)
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["capturedAtUtc"] = ["The captured time must be within the last 24 hours and not more than 2 minutes in the future."]
            });

        var location = await locations.GetAsync(driverId, cancellationToken);
        if (location is null)
        {
            location = new DriverLocation(
                driverId,
                request.Latitude,
                request.Longitude,
                request.AccuracyMeters,
                request.HeadingDegrees,
                request.SpeedMetersPerSecond,
                request.CapturedAtUtc,
                now);
            await locations.AddAsync(location, cancellationToken);
        }
        else
        {
            location.Update(
                request.Latitude,
                request.Longitude,
                request.AccuracyMeters,
                request.HeadingDegrees,
                request.SpeedMetersPerSecond,
                request.CapturedAtUtc,
                now);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(driver, location, now, []);
    }

    public async Task<IReadOnlyList<DriverLocationResponse>> ListDriversAsync(CancellationToken cancellationToken)
    {
        var drivers = await users.GetActiveByRoleAsync(UserRole.Driver, cancellationToken);
        var latest = await locations.ListAsync(drivers.Select(driver => driver.Id).ToArray(), cancellationToken);
        var byDriver = latest.ToDictionary(location => location.DriverId);
        var workloads = await orders.ListActiveByDriversAsync(drivers.Select(driver => driver.Id).ToArray(), cancellationToken);
        var workloadByDriver = workloads
            .Where(order => order.AssignedDriverId.HasValue)
            .GroupBy(order => order.AssignedDriverId!.Value)
            .ToDictionary(group => group.Key, group => group.ToList());
        var now = clock.UtcNow;

        return drivers
            .Select(driver => Map(
                driver,
                byDriver.GetValueOrDefault(driver.Id),
                now,
                workloadByDriver.GetValueOrDefault(driver.Id) ?? []))
            .ToList();
    }

    public async Task<DriverLocationResponse?> GetDriverAsync(Guid driverId, CancellationToken cancellationToken)
    {
        var driver = await users.GetByIdAsync(driverId, cancellationToken);
        if (driver is null || !driver.IsActive || driver.Role != UserRole.Driver) return null;

        var location = await locations.GetAsync(driverId, cancellationToken);
        return Map(driver, location, clock.UtcNow, []);
    }

    private static void Validate(UpdateDriverLocationRequest request)
    {
        var errors = new Dictionary<string, string[]>();
        if (double.IsNaN(request.Latitude) || request.Latitude is < -90 or > 90)
            errors["latitude"] = ["Latitude must be between -90 and 90."];
        if (double.IsNaN(request.Longitude) || request.Longitude is < -180 or > 180)
            errors["longitude"] = ["Longitude must be between -180 and 180."];
        if (double.IsNaN(request.AccuracyMeters) || request.AccuracyMeters is < 0 or > 2_000)
            errors["accuracyMeters"] = ["Accuracy must be between 0 and 2,000 metres."];
        if (request.HeadingDegrees is { } heading && (double.IsNaN(heading) || heading is < 0 or >= 360))
            errors["headingDegrees"] = ["Heading must be at least 0 and less than 360 degrees."];
        if (request.SpeedMetersPerSecond is { } speed && (double.IsNaN(speed) || speed is < 0 or > 100))
            errors["speedMetersPerSecond"] = ["Speed must be between 0 and 100 metres per second."];
        if (request.CapturedAtUtc == default)
            errors["capturedAtUtc"] = ["Captured time is required."];

        if (errors.Count > 0) throw new ValidationException(errors);
    }

    private static DriverLocationResponse Map(
        User driver,
        DriverLocation? location,
        DateTimeOffset now,
        IReadOnlyList<Order> workload)
    {
        var activeOrders = workload.Select(order => new DriverLoadOrderResponse(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.Lines.Sum(line => line.Quantity),
            order.Total,
            order.DeliveryAddress)).ToList();
        var activeItemCount = activeOrders.Sum(order => order.ItemCount);
        if (location is null)
        {
            return new DriverLocationResponse(
                driver.Id,
                driver.DisplayName,
                LocationFreshness.Unavailable,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                activeOrders.Count,
                activeItemCount,
                activeOrders);
        }

        var age = now - location.ReceivedAtUtc;
        var freshness = age <= TimeSpan.FromSeconds(15)
            ? LocationFreshness.Live
            : age <= TimeSpan.FromMinutes(1)
                ? LocationFreshness.Recent
                : LocationFreshness.Stale;

        return new DriverLocationResponse(
            driver.Id,
            driver.DisplayName,
            freshness,
            location.Latitude,
            location.Longitude,
            location.AccuracyMeters,
            location.HeadingDegrees,
            location.SpeedMetersPerSecond,
            location.CapturedAtUtc,
            location.ReceivedAtUtc,
            activeOrders.Count,
            activeItemCount,
            activeOrders);
    }
}
