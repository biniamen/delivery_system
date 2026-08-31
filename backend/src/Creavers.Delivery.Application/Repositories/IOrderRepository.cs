using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Repositories;

public interface IOrderRepository
{
    Task AddAsync(Order order, CancellationToken cancellationToken);
    Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<Order?> GetByIdempotencyKeyAsync(Guid customerId, string idempotencyKey, CancellationToken cancellationToken);
    Task<IReadOnlyList<Order>> ListAsync(OrderStatus? status, Guid? driverId, CancellationToken cancellationToken);
}

