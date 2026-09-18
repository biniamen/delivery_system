using Creavers.Delivery.Application.Drivers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize(Policy = "DispatcherOnly")]
[Route("api/v1/drivers")]
public sealed class DriversController(IDriverService drivers) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<DriverAccountResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<DriverAccountResponse>>> List(
        CancellationToken cancellationToken) =>
        Ok(await drivers.ListAsync(cancellationToken));

    [HttpGet("available")]
    [ProducesResponseType<IReadOnlyList<DriverAccountResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<DriverAccountResponse>>> GetAvailable(
        [FromQuery] Guid? forOrderId,
        CancellationToken cancellationToken) =>
        Ok(await drivers.GetAvailableAsync(forOrderId, cancellationToken));

    [HttpPost]
    [ProducesResponseType<DriverAccountResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<DriverAccountResponse>> Create(
        CreateDriverRequest request,
        CancellationToken cancellationToken)
    {
        var driver = await drivers.CreateAsync(request, cancellationToken);
        return Created($"/api/v1/drivers/{driver.Id}", driver);
    }

    [HttpPut("{driverId:guid}/status")]
    [ProducesResponseType<DriverAccountResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<DriverAccountResponse>> SetStatus(
        Guid driverId,
        SetDriverStatusRequest request,
        CancellationToken cancellationToken) =>
        Ok(await drivers.SetActiveAsync(driverId, request, cancellationToken));
}
