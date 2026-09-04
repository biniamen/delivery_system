using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;

namespace Creavers.Delivery.Application.Catalogue;

public sealed class ProductAdminService(
    ICatalogueRepository catalogue,
    IUnitOfWork unitOfWork) : IProductAdminService
{
    public async Task<AdminCatalogueResponse> GetAsync(CancellationToken cancellationToken)
    {
        var categories = await catalogue.GetCatalogueAsync(cancellationToken);
        return new AdminCatalogueResponse(
            categories.OrderBy(category => category.DisplayOrder)
                .Select(category => new AdminCategoryResponse(category.Id, category.Name, category.Slug))
                .ToList(),
            categories.SelectMany(category => category.Products.Select(product => Map(product, category.Name)))
                .OrderBy(product => product.CategoryName)
                .ThenBy(product => product.Name)
                .ToList());
    }

    public async Task<AdminProductResponse> CreateAsync(
        SaveProductRequest request,
        CancellationToken cancellationToken)
    {
        Validate(request);
        var category = await GetCategoryAsync(request.CategoryId, cancellationToken);
        var product = new Product(
            Guid.NewGuid(),
            request.CategoryId,
            request.Name,
            request.Description,
            request.Unit,
            request.Price,
            request.ImageUrl,
            request.StockQuantity);
        if (request.IsAvailable) product.SetAvailability(true);
        else product.SetAvailability(false);

        await catalogue.AddProductAsync(product, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(product, category.Name);
    }

    public async Task<AdminProductResponse> UpdateAsync(
        Guid productId,
        SaveProductRequest request,
        CancellationToken cancellationToken)
    {
        Validate(request);
        var category = await GetCategoryAsync(request.CategoryId, cancellationToken);
        var product = await GetProductAsync(productId, cancellationToken);
        product.UpdateDetails(
            request.CategoryId,
            request.Name,
            request.Description,
            request.Unit,
            request.Price,
            request.ImageUrl,
            request.StockQuantity);
        product.SetAvailability(request.IsAvailable);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(product, category.Name);
    }

    public async Task<AdminProductResponse> SetAvailabilityAsync(
        Guid productId,
        SetProductAvailabilityRequest request,
        CancellationToken cancellationToken)
    {
        var product = await GetProductAsync(productId, cancellationToken);
        try
        {
            product.SetAvailability(request.IsAvailable);
        }
        catch (InvalidOperationException exception)
        {
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["isAvailable"] = [exception.Message]
            });
        }

        var category = await GetCategoryAsync(product.CategoryId, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(product, category.Name);
    }

    private async Task<Product> GetProductAsync(Guid productId, CancellationToken cancellationToken) =>
        await catalogue.GetProductAsync(productId, cancellationToken)
        ?? throw new NotFoundException($"Product '{productId}' was not found.");

    private async Task<Category> GetCategoryAsync(Guid categoryId, CancellationToken cancellationToken) =>
        await catalogue.GetCategoryAsync(categoryId, cancellationToken)
        ?? throw new ValidationException(new Dictionary<string, string[]>
        {
            ["categoryId"] = ["Select an existing category."]
        });

    private static void Validate(SaveProductRequest request)
    {
        var errors = new Dictionary<string, string[]>();
        if (request.CategoryId == Guid.Empty) errors["categoryId"] = ["Category is required."];
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 150)
            errors["name"] = ["Name is required and must not exceed 150 characters."];
        if (string.IsNullOrWhiteSpace(request.Description) || request.Description.Length > 500)
            errors["description"] = ["Description is required and must not exceed 500 characters."];
        if (string.IsNullOrWhiteSpace(request.Unit) || request.Unit.Length > 50)
            errors["unit"] = ["Unit is required and must not exceed 50 characters."];
        if (request.Price < 0) errors["price"] = ["Price cannot be negative."];
        if (request.StockQuantity < 0) errors["stockQuantity"] = ["Stock cannot be negative."];
        if (request.IsAvailable && request.StockQuantity == 0)
            errors["stockQuantity"] = ["Add stock before making this product available."];
        if (string.IsNullOrWhiteSpace(request.ImageUrl) || request.ImageUrl.Length > 500)
            errors["imageUrl"] = ["Image URL is required and must not exceed 500 characters."];
        if (errors.Count > 0) throw new ValidationException(errors);
    }

    private static AdminProductResponse Map(Product product, string categoryName) => new(
        product.Id,
        product.CategoryId,
        categoryName,
        product.Name,
        product.Description,
        product.Unit,
        product.Price,
        product.ImageUrl,
        product.StockQuantity,
        product.IsActive && product.StockQuantity > 0);
}
