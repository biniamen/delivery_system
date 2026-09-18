using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Drivers;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class DriverManagementTests
{
    [Fact]
    public async Task DispatcherCanProvisionAnActiveDriverWithHashedTemporaryPassword()
    {
        var users = new InMemoryUserRepository();
        var unitOfWork = new RecordingUnitOfWork();
        var passwords = new FakePasswordService();
        var service = new DriverService(users, new InMemoryOrderRepository(), passwords, unitOfWork);

        var created = await service.CreateAsync(
            new CreateDriverRequest(
                "  Hana Driver  ",
                "HANA.DRIVER@EXAMPLE.COM",
                "0911 222 333",
                "Creavers#2026"),
            default);

        var stored = Assert.Single(users.Users);
        Assert.Equal("Hana Driver", created.DisplayName);
        Assert.Equal("hana.driver@example.com", created.Email);
        Assert.Equal("+251911222333", created.PhoneNumber);
        Assert.True(created.IsActive);
        Assert.Equal(UserRole.Driver, created.Role);
        Assert.Equal("hash:Creavers#2026", stored.PasswordHash);
        Assert.Equal(1, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task DuplicateDriverEmailIsRejected()
    {
        var existing = new User(Guid.NewGuid(), "driver@example.com", "Existing Driver", UserRole.Driver);
        var users = new InMemoryUserRepository(existing);
        var unitOfWork = new RecordingUnitOfWork();
        var service = new DriverService(users, new InMemoryOrderRepository(), new FakePasswordService(), unitOfWork);

        var action = () => service.CreateAsync(
            new CreateDriverRequest(
                "Another Driver",
                "driver@example.com",
                "+251911222334",
                "Creavers#2026"),
            default);

        await Assert.ThrowsAsync<ConflictException>(action);
        Assert.Single(users.Users);
        Assert.Equal(0, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task DriverWithActiveDeliveryCannotBeDeactivated()
    {
        var driver = new User(Guid.NewGuid(), "driver@example.com", "Active Driver", UserRole.Driver);
        var order = CreateOrder();
        order.AssignDriver(driver.Id, Guid.NewGuid(), DateTimeOffset.UtcNow);
        var unitOfWork = new RecordingUnitOfWork();
        var service = new DriverService(
            new InMemoryUserRepository(driver),
            new InMemoryOrderRepository(order),
            new FakePasswordService(),
            unitOfWork);

        var action = () => service.SetActiveAsync(
            driver.Id,
            new SetDriverStatusRequest(false),
            default);

        var exception = await Assert.ThrowsAsync<ConflictException>(action);
        Assert.Contains("active delivery", exception.Message, StringComparison.OrdinalIgnoreCase);
        Assert.True(driver.IsActive);
        Assert.Equal(0, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task DispatcherCanDeactivateAndReactivateAnAvailableDriver()
    {
        var driver = new User(Guid.NewGuid(), "driver@example.com", "Available Driver", UserRole.Driver);
        var unitOfWork = new RecordingUnitOfWork();
        var service = new DriverService(
            new InMemoryUserRepository(driver),
            new InMemoryOrderRepository(),
            new FakePasswordService(),
            unitOfWork);

        var inactive = await service.SetActiveAsync(
            driver.Id,
            new SetDriverStatusRequest(false),
            default);
        var active = await service.SetActiveAsync(
            driver.Id,
            new SetDriverStatusRequest(true),
            default);

        Assert.False(inactive.IsActive);
        Assert.True(active.IsActive);
        Assert.Equal(2, unitOfWork.SaveCount);
    }

    private static Order CreateOrder() => Order.Create(
        Guid.NewGuid(),
        "CRV-DRIVER-MGMT",
        Guid.NewGuid(),
        Guid.NewGuid().ToString("N"),
        "Demo Customer",
        "+251911234567",
        "Bole, Addis Ababa",
        9.0192,
        38.7525,
        PaymentMethod.DemoCash,
        80m,
        [new OrderLine(Guid.NewGuid(), Guid.NewGuid(), "Coffee", "500 g", 1, 125m)],
        DateTimeOffset.UtcNow);

    private sealed class InMemoryUserRepository(params User[] seed) : IUserRepository
    {
        public List<User> Users { get; } = [.. seed];

        public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken) =>
            Task.FromResult(Users.SingleOrDefault(user => user.Email == normalizedEmail));

        public Task<User?> GetByPhoneAsync(string normalizedPhoneNumber, CancellationToken cancellationToken) =>
            Task.FromResult(Users.SingleOrDefault(user => user.PhoneNumber == normalizedPhoneNumber));

        public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(Users.SingleOrDefault(user => user.Id == id));

        public Task<IReadOnlyList<User>> GetByRoleAsync(UserRole role, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<User>>(Users.Where(user => user.Role == role).ToList());

        public Task<IReadOnlyList<User>> GetActiveByRoleAsync(UserRole role, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<User>>(
                Users.Where(user => user.Role == role && user.IsActive).ToList());

        public Task AddAsync(User user, CancellationToken cancellationToken)
        {
            Users.Add(user);
            return Task.CompletedTask;
        }
    }

    private sealed class InMemoryOrderRepository(params Order[] seed) : IOrderRepository
    {
        private readonly List<Order> orders = [.. seed];

        public Task AddAsync(Order order, CancellationToken cancellationToken) => Task.CompletedTask;

        public Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(orders.SingleOrDefault(order => order.Id == id));

        public Task<Order?> GetByIdempotencyKeyAsync(
            Guid customerId,
            string idempotencyKey,
            CancellationToken cancellationToken) => Task.FromResult<Order?>(null);

        public Task<IReadOnlyList<Order>> ListAsync(
            OrderStatus? status,
            Guid? driverId,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>(orders);

        public Task<IReadOnlyList<Order>> ListForCustomerAsync(
            Guid customerId,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>(orders.Where(order => order.CustomerId == customerId).ToList());

        public Task<IReadOnlyList<Order>> ListActiveByDriversAsync(
            IReadOnlyCollection<Guid> driverIds,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>(orders.Where(order =>
                order.AssignedDriverId.HasValue &&
                driverIds.Contains(order.AssignedDriverId.Value) &&
                order.Status is not (OrderStatus.Delivered or OrderStatus.DeliveryConfirmed or OrderStatus.Cancelled)).ToList());

        public Task<bool> HasActiveAssignmentAsync(
            Guid driverId,
            Guid? excludedOrderId,
            CancellationToken cancellationToken) =>
            Task.FromResult(orders.Any(order =>
                order.AssignedDriverId == driverId &&
                (!excludedOrderId.HasValue || order.Id != excludedOrderId.Value) &&
                order.Status is not (OrderStatus.Delivered or OrderStatus.DeliveryConfirmed or OrderStatus.Cancelled)));
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

    private sealed class FakePasswordService : IPasswordService
    {
        public string Hash(User user, string password) => $"hash:{password}";

        public bool Verify(User user, string passwordHash, string suppliedPassword) =>
            passwordHash == $"hash:{suppliedPassword}";
    }
}
