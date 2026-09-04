using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Locations;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Creavers.Delivery.Domain.Exceptions;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class DriverLocationTests
{
    private static readonly DateTimeOffset Now = new(2026, 8, 31, 11, 30, 0, TimeSpan.Zero);

    [Fact]
    public void LocationRejectsOutOfRangeCoordinates()
    {
        var action = () => new DriverLocation(
            Guid.NewGuid(),
            91,
            38.76,
            8,
            null,
            null,
            Now,
            Now);

        Assert.Throws<DomainRuleException>(action);
    }

    [Fact]
    public async Task RecordingLocationReplacesTheCurrentDriverPosition()
    {
        var driver = ActiveDriver();
        var repository = new InMemoryLocationRepository();
        var unitOfWork = new RecordingUnitOfWork();
        var service = new DriverLocationService(
            repository,
            new InMemoryUserRepository(driver),
            new EmptyOrderRepository(),
            unitOfWork,
            new FixedClock(Now));

        var first = await service.RecordAsync(driver.Id, Request(9.01, 38.75, Now.AddSeconds(-10)), default);
        var second = await service.RecordAsync(driver.Id, Request(9.02, 38.76, Now), default);

        Assert.Equal(LocationFreshness.Live, first.Freshness);
        Assert.Equal(9.02, second.Latitude);
        Assert.Single(repository.Locations);
        Assert.Equal(2, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task RecordingRejectsAnExpiredCapture()
    {
        var driver = ActiveDriver();
        var service = new DriverLocationService(
            new InMemoryLocationRepository(),
            new InMemoryUserRepository(driver),
            new EmptyOrderRepository(),
            new RecordingUnitOfWork(),
            new FixedClock(Now));

        var action = () => service.RecordAsync(
            driver.Id,
            Request(9.01, 38.75, Now.AddHours(-25)),
            default);

        await Assert.ThrowsAsync<ValidationException>(action);
    }

    private static User ActiveDriver() => new(Guid.NewGuid(), "driver@test.local", "Test Driver", UserRole.Driver);

    private static UpdateDriverLocationRequest Request(double latitude, double longitude, DateTimeOffset capturedAt) =>
        new(latitude, longitude, 7.5, 42, 5.2, capturedAt);

    private sealed class FixedClock(DateTimeOffset now) : IClock
    {
        public DateTimeOffset UtcNow => now;
    }

    private sealed class RecordingUnitOfWork : IUnitOfWork
    {
        public int SaveCount { get; private set; }

        public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            SaveCount++;
            return Task.FromResult(1);
        }
    }

    private sealed class InMemoryLocationRepository : IDriverLocationRepository
    {
        public List<DriverLocation> Locations { get; } = [];

        public Task<DriverLocation?> GetAsync(Guid driverId, CancellationToken cancellationToken) =>
            Task.FromResult(Locations.SingleOrDefault(location => location.DriverId == driverId));

        public Task<IReadOnlyList<DriverLocation>> ListAsync(
            IReadOnlyCollection<Guid> driverIds,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<DriverLocation>>(
                Locations.Where(location => driverIds.Contains(location.DriverId)).ToList());

        public Task AddAsync(DriverLocation location, CancellationToken cancellationToken)
        {
            Locations.Add(location);
            return Task.CompletedTask;
        }
    }

    private sealed class InMemoryUserRepository(params User[] users) : IUserRepository
    {
        public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken) =>
            Task.FromResult(users.SingleOrDefault(user => user.Email == normalizedEmail));

        public Task<User?> GetByPhoneAsync(string normalizedPhoneNumber, CancellationToken cancellationToken) =>
            Task.FromResult(users.SingleOrDefault(user => user.PhoneNumber == normalizedPhoneNumber));

        public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(users.SingleOrDefault(user => user.Id == id));

        public Task<IReadOnlyList<User>> GetActiveByRoleAsync(UserRole role, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<User>>(users.Where(user => user.Role == role && user.IsActive).ToList());

        public Task AddAsync(User user, CancellationToken cancellationToken) => Task.CompletedTask;
    }

    private sealed class EmptyOrderRepository : IOrderRepository
    {
        public Task AddAsync(Order order, CancellationToken cancellationToken) => Task.CompletedTask;
        public Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken) => Task.FromResult<Order?>(null);
        public Task<Order?> GetByIdempotencyKeyAsync(Guid customerId, string idempotencyKey, CancellationToken cancellationToken) =>
            Task.FromResult<Order?>(null);
        public Task<IReadOnlyList<Order>> ListAsync(OrderStatus? status, Guid? driverId, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>([]);

        public Task<IReadOnlyList<Order>> ListForCustomerAsync(Guid customerId, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>([]);
        public Task<IReadOnlyList<Order>> ListActiveByDriversAsync(
            IReadOnlyCollection<Guid> driverIds,
            CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<Order>>([]);
    }
}
