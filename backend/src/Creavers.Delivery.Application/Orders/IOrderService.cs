using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Orders;

public interface IOrderService
{
    Task<OrderResponse> CreateAsync(Guid customerId, CreateOrderRequest request, CancellationToken cancellationToken);
    Task<IReadOnlyList<OrderSummaryResponse>> ListAsync(OrderStatus? status, Guid? driverId, CancellationToken cancellationToken);
    Task<IReadOnlyList<OrderSummaryResponse>> ListForCustomerAsync(Guid customerId, CancellationToken cancellationToken);
    Task<OrderResponse> GetAsync(Guid id, CancellationToken cancellationToken);
    Task<OrderResponse> AssignAsync(Guid id, Guid dispatcherId, AssignDriverRequest request, CancellationToken cancellationToken);
    Task<OrderResponse> TransitionAsync(Guid id, Guid actorId, TransitionOrderRequest request, CancellationToken cancellationToken);
}
