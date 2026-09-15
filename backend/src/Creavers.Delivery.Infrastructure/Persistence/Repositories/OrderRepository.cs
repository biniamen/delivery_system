using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Creavers.Delivery.Infrastructure.Persistence.Repositories;

public sealed class OrderRepository(DeliveryDbContext dbContext) : IOrderRepository
{
    public Task AddAsync(Order order, CancellationToken cancellationToken) =>
        dbContext.Orders.AddAsync(order, cancellationToken).AsTask();

    public Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
        QueryWithDetails().SingleOrDefaultAsync(order => order.Id == id, cancellationToken);

    public Task<Order?> GetByIdempotencyKeyAsync(
        Guid customerId,
        string idempotencyKey,
        CancellationToken cancellationToken) =>
        QueryWithDetails().SingleOrDefaultAsync(
            order => order.CustomerId == customerId && order.IdempotencyKey == idempotencyKey,
            cancellationToken);

    public async Task<IReadOnlyList<Order>> ListAsync(
        OrderStatus? status,
        Guid? driverId,
        CancellationToken cancellationToken)
    {
        IQueryable<Order> query = dbContext.Orders.AsNoTracking();
        if (status.HasValue) query = query.Where(order => order.Status == status.Value);
        if (driverId.HasValue) query = query.Where(order => order.AssignedDriverId == driverId.Value);

        return await query.OrderByDescending(order => order.CreatedAtUtc).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Order>> ListForCustomerAsync(
        Guid customerId,
        CancellationToken cancellationToken) =>
        await dbContext.Orders
            .AsNoTracking()
            .Where(order => order.CustomerId == customerId)
            .OrderByDescending(order => order.CreatedAtUtc)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<Order>> ListActiveByDriversAsync(
        IReadOnlyCollection<Guid> driverIds,
        CancellationToken cancellationToken) =>
        await dbContext.Orders
            .AsNoTracking()
            .Include(order => order.Lines)
            .Where(order =>
                order.AssignedDriverId.HasValue &&
                driverIds.Contains(order.AssignedDriverId.Value) &&
                order.Status != OrderStatus.Delivered &&
                order.Status != OrderStatus.Cancelled)
            .OrderBy(order => order.CreatedAtUtc)
            .ToListAsync(cancellationToken);

    public Task<bool> HasActiveAssignmentAsync(
        Guid driverId,
        Guid? excludedOrderId,
        CancellationToken cancellationToken) =>
        dbContext.Orders
            .AsNoTracking()
            .AnyAsync(
                order =>
                    order.AssignedDriverId == driverId &&
                    (!excludedOrderId.HasValue || order.Id != excludedOrderId.Value) &&
                    order.Status != OrderStatus.Delivered &&
                    order.Status != OrderStatus.Cancelled,
                cancellationToken);

    private IQueryable<Order> QueryWithDetails() => dbContext.Orders
        .AsSplitQuery()
        .Include(order => order.Lines)
        .Include(order => order.StatusHistory)
        .Include(order => order.Assignments);
}
