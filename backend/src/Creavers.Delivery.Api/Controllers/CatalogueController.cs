using Creavers.Delivery.Application.Catalogue;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/catalogue")]
public sealed class CatalogueController(ICatalogueService catalogue) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<CategoryResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<CategoryResponse>>> Get(CancellationToken cancellationToken) =>
        Ok(await catalogue.GetAsync(cancellationToken));
}

