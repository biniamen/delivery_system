using System.Security.Claims;
using Creavers.Delivery.Api.Extensions;
using Creavers.Delivery.Application.Orders;
using Creavers.Delivery.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/orders")]
public sealed class OrdersController(IOrderService orders) : ControllerBase
{
    [HttpGet]
    [Authorize(Policy = "DispatcherOnly")]
    [ProducesResponseType<IReadOnlyList<OrderSummaryResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<OrderSummaryResponse>>> List(
        [FromQuery] OrderStatus? status,
        CancellationToken cancellationToken) =>
        Ok(await orders.ListAsync(status, null, cancellationToken));

    [HttpGet("assigned-to-me")]
    [Authorize(Policy = "DriverOnly")]
    [ProducesResponseType<IReadOnlyList<OrderSummaryResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<OrderSummaryResponse>>> AssignedToMe(CancellationToken cancellationToken) =>
        Ok(await orders.ListAsync(null, User.GetRequiredUserId(), cancellationToken));

    [HttpGet("mine")]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType<IReadOnlyList<OrderSummaryResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<OrderSummaryResponse>>> Mine(CancellationToken cancellationToken) =>
        Ok(await orders.ListForCustomerAsync(User.GetRequiredUserId(), cancellationToken));

    [HttpGet("{id:guid}")]
    [ProducesResponseType<OrderResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OrderResponse>> Get(Guid id, CancellationToken cancellationToken)
    {
        var order = await orders.GetAsync(id, cancellationToken);
        var userId = User.GetRequiredUserId();
        var role = User.FindFirstValue(ClaimTypes.Role);

        var canView = role == UserRole.Dispatcher.ToString()
            || (role == UserRole.Customer.ToString() && order.CustomerId == userId)
            || (role == UserRole.Driver.ToString() && order.AssignedDriverId == userId);

        return canView ? Ok(order) : Forbid();
    }

    [HttpPost]
    [Authorize(Policy = "CustomerOnly")]
    [ProducesResponseType<OrderResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<OrderResponse>> Create(
        CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var order = await orders.CreateAsync(User.GetRequiredUserId(), request, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = order.Id }, order);
    }

    [HttpPut("{id:guid}/assignment")]
    [Authorize(Policy = "DispatcherOnly")]
    [ProducesResponseType<OrderResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderResponse>> Assign(
        Guid id,
        AssignDriverRequest request,
        CancellationToken cancellationToken) =>
        Ok(await orders.AssignAsync(id, User.GetRequiredUserId(), request, cancellationToken));

    [HttpPost("{id:guid}/transitions")]
    [Authorize(Policy = "DriverOnly")]
    [ProducesResponseType<OrderResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderResponse>> Transition(
        Guid id,
        TransitionOrderRequest request,
        CancellationToken cancellationToken) =>
        Ok(await orders.TransitionAsync(id, User.GetRequiredUserId(), request, cancellationToken));
}
