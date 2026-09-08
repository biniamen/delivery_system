using Creavers.Delivery.Application.Catalogue;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize(Policy = "StoreAdminOnly")]
[Route("api/v1/admin/products")]
public sealed class AdminProductsController(IProductAdminService products) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<AdminCatalogueResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminCatalogueResponse>> Get(CancellationToken cancellationToken) =>
        Ok(await products.GetAsync(cancellationToken));

    [HttpPost]
    [ProducesResponseType<AdminProductResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AdminProductResponse>> Create(
        SaveProductRequest request,
        CancellationToken cancellationToken)
    {
        var product = await products.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = product.Id }, product);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType<AdminProductResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminProductResponse>> Update(
        Guid id,
        SaveProductRequest request,
        CancellationToken cancellationToken) =>
        Ok(await products.UpdateAsync(id, request, cancellationToken));

    [HttpPatch("{id:guid}/availability")]
    [ProducesResponseType<AdminProductResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminProductResponse>> SetAvailability(
        Guid id,
        SetProductAvailabilityRequest request,
        CancellationToken cancellationToken) =>
        Ok(await products.SetAvailabilityAsync(id, request, cancellationToken));
}
