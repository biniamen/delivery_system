using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Drivers;
using Creavers.Delivery.Application.Orders;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class AssignmentWorkflowTests
{
    private static readonly DateTimeOffset Now = new(2026, 9, 14, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task AvailableDriversExcludeDriversWithAnotherActiveDelivery()
    {
        var busyDriver = Driver("busy@demo.local", "Busy Driver");
        var freeDriver = Driver("free@demo.local", "Free Driver");
        var activeOrder = OrderFor(Guid.NewGuid());
        activeOrder.AssignDriver(busyDriver.Id, Guid.NewGuid(), Now);
        var orders = new InMemoryOrderRepository(activeOrder);
        var service = new DriverService(
            new InMemoryUserRepository(busyDriver, freeDriver),
            orders);

        var available = await service.GetAvailableAsync(null, default);
        var availableForCurrentOrder = await service.GetAvailableAsync(activeOrder.Id, default);

        Assert.Collection(available, driver => Assert.Equal(freeDriver.Id, driver.Id));
        Assert.Equal(2, availableForCurrentOrder.Count);
        Assert.Contains(availableForCurrentOrder, driver => driver.Id == busyDriver.Id);
    }

    [Fact]
    public async Task AssignmentRejectsDriverWhoAlreadyHasAnotherActiveDelivery()
    {
        var driver = Driver("busy@demo.local", "Busy Driver");
        var existingOrder = OrderFor(Guid.NewGuid());
        existingOrder.AssignDriver(driver.Id, Guid.NewGuid(), Now);
        var orderToAssign = OrderFor(Guid.NewGuid());
        var repository = new InMemoryOrderRepository(existingOrder, orderToAssign);
        var unitOfWork = new RecordingUnitOfWork();
        var service = CreateOrderService(repository, new InMemoryUserRepository(driver), unitOfWork);

        var action = () => service.AssignAsync(
            orderToAssign.Id,
            Guid.NewGuid(),
            new AssignDriverRequest(driver.Id),
            default);

        var exception = await Assert.ThrowsAsync<ConflictException>(action);
        Assert.Contains("active delivery", exception.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(OrderStatus.New, orderToAssign.Status);
        Assert.Equal(0, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task RepeatingTheSamePutAssignmentDoesNotDuplicateAuditHistory()
    {
        var driver = Driver("driver@demo.local", "Demo Driver");
        var order = OrderFor(Guid.NewGuid());
        var repository = new InMemoryOrderRepository(order);
        var unitOfWork = new RecordingUnitOfWork();
        var service = CreateOrderService(repository, new InMemoryUserRepository(driver), unitOfWork);
        var request = new AssignDriverRequest(driver.Id);
        var dispatcherId = Guid.NewGuid();

        var first = await service.AssignAsync(order.Id, dispatcherId, request, default);
        var retry = await service.AssignAsync(order.Id, dispatcherId, request, default);

        Assert.Equal(OrderStatus.Assigned, retry.Status);
        Assert.Equal(driver.Id, retry.AssignedDriverId);
        Assert.Single(first.AssignmentHistory);
        Assert.Single(retry.AssignmentHistory);
        Assert.Equal(1, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task AssignedDriverCanAcceptAndTheTransitionIsAudited()
    {
        var driver = Driver("driver@demo.local", "Demo Driver");
        var order = OrderFor(Guid.NewGuid());
        order.AssignDriver(driver.Id, Guid.NewGuid(), Now.AddMinutes(-5));
        var repository = new InMemoryOrderRepository(order);
        var unitOfWork = new RecordingUnitOfWork();
        var service = CreateOrderService(repository, new InMemoryUserRepository(driver), unitOfWork);

        var accepted = await service.TransitionAsync(
            order.Id,
            driver.Id,
            new TransitionOrderRequest(OrderStatus.Accepted, "Delivery accepted"),
            default);

        Assert.Equal(OrderStatus.Accepted, accepted.Status);
        Assert.Equal(driver.Id, accepted.AssignedDriverId);
        Assert.Equal(OrderStatus.Accepted, accepted.StatusHistory[^1].Status);
        Assert.Equal(driver.Id, accepted.StatusHistory[^1].ChangedByUserId);
        Assert.Equal(1, unitOfWork.SaveCount);
    }

    [Fact]
    public async Task UnassignedDriverCannotAcceptAnotherDriversDelivery()
    {
        var assignedDriver = Driver("assigned@demo.local", "Assigned Driver");
        var otherDriver = Driver("other@demo.local", "Other Driver");
        var order = OrderFor(Guid.NewGuid());
        order.AssignDriver(assignedDriver.Id, Guid.NewGuid(), Now.AddMinutes(-5));
        var repository = new InMemoryOrderRepository(order);
        var unitOfWork = new RecordingUnitOfWork();
        var service = CreateOrderService(
            repository,
            new InMemoryUserRepository(assignedDriver, otherDriver),
            unitOfWork);

        var action = () => service.TransitionAsync(
            order.Id,
            otherDriver.Id,
            new TransitionOrderRequest(OrderStatus.Accepted, null),
            default);

        var exception = await Assert.ThrowsAsync<ConflictException>(action);
        Assert.Contains("assigned driver", exception.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(OrderStatus.Assigned, order.Status);
        Assert.Equal(0, unitOfWork.SaveCount);
    }

    private static OrderService CreateOrderService(
        InMemoryOrderRepository orders,
        InMemoryUserRepository users,
        RecordingUnitOfWork unitOfWork) =>
        new(orders, new EmptyCatalogueRepository(), users, unitOfWork, new FixedClock());

    private static User Driver(string email, string name) =>
        new(Guid.NewGuid(), email, name, UserRole.Driver);

    private static Order OrderFor(Guid customerId) => Order.Create(
        Guid.NewGuid(),
        $"CRV-TEST-{Guid.NewGuid():N}",
        customerId,
        Guid.NewGuid().ToString("N"),
        "Demo Customer",
        "+251911234567",
        "CMC, Addis Ababa",
        9.0294,
        38.8517,
        PaymentMethod.DemoCash,
        80m,
        [new OrderLine(Guid.NewGuid(), Guid.NewGuid(), "Coffee", "500 g", 1, 125m)],
        Now.AddMinutes(-10));

    private sealed class FixedClock : IClock
    {
        public DateTimeOffset UtcNow => Now;
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

    private sealed class InMemoryUserRepository(params User[] users) : IUserRepository
    {
        public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken) =>
            Task.FromResult(users.SingleOrDefault(user => user.Email == normalizedEmail));

        public Task<User?> GetByPhoneAsync(string normalizedPhoneNumber, CancellationToken cancellationToken) =>
            Task.FromResult(users.SingleOrDefault(user => user.PhoneNumber == normalizedPhoneNumber));

        public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(users.SingleOrDefault(user => user.Id == id));

        public Task<IReadOnlyList<User>> GetActiveByRoleAsync(UserRole role, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<User>>(
                users.Where(user => user.Role == role && user.IsActive).OrderBy(user => user.DisplayName).ToList());

        public Task AddAsync(User user, CancellationToken cancellationToken) => Task.CompletedTask;
    }

    private sealed class InMemoryOrderRepository(params Order[] orders) : IOrderRepository
    {
        private readonly List<Order> _orders = [.. orders];

        public Task AddAsync(Order order, CancellationToken cancellationToken)
        {
            _orders.Add(order);
            return Task.CompletedTask;
        }

        public Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(_orders.SingleOrDefault(order => order.Id == id));

        public Task<Order?> GetByIdempotencyKeyAsync(
            Guid customerId,
            string idempotencyKey,
            CancellationToken cancellationToken) =>
            Task.FromResult(_orders.SingleOrDefault(
                order => order.CustomerId == customerId && order.IdempotencyKey == idempotencyKey));

        public Task<IReadOnlyList<Order>> ListAsync(
            OrderStatus? status,
            Guid? driverId,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>(_orders
                .Where(order => !status.HasValue || order.Status == status.Value)
                .Where(order => !driverId.HasValue || order.AssignedDriverId == driverId.Value)
                .ToList());

        public Task<IReadOnlyList<Order>> ListForCustomerAsync(
            Guid customerId,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>(
                _orders.Where(order => order.CustomerId == customerId).ToList());

        public Task<IReadOnlyList<Order>> ListActiveByDriversAsync(
            IReadOnlyCollection<Guid> driverIds,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Order>>(_orders
                .Where(order =>
                    order.AssignedDriverId.HasValue &&
                    driverIds.Contains(order.AssignedDriverId.Value) &&
                    order.Status is not (OrderStatus.Delivered or OrderStatus.Cancelled))
                .ToList());

        public Task<bool> HasActiveAssignmentAsync(
            Guid driverId,
            Guid? excludedOrderId,
            CancellationToken cancellationToken) =>
            Task.FromResult(_orders.Any(order =>
                order.AssignedDriverId == driverId &&
                (!excludedOrderId.HasValue || order.Id != excludedOrderId.Value) &&
                order.Status is not (OrderStatus.Delivered or OrderStatus.Cancelled)));
    }

    private sealed class EmptyCatalogueRepository : ICatalogueRepository
    {
        public Task<IReadOnlyList<Category>> GetCatalogueAsync(CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<Category>>([]);

        public Task<IReadOnlyDictionary<Guid, Product>> GetActiveProductsAsync(
            IEnumerable<Guid> ids,
            CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyDictionary<Guid, Product>>(new Dictionary<Guid, Product>());

        public Task<Product?> GetProductAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult<Product?>(null);

        public Task<Category?> GetCategoryAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult<Category?>(null);

        public Task AddProductAsync(Product product, CancellationToken cancellationToken) =>
            Task.CompletedTask;
    }
}
