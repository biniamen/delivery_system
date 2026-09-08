using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Catalogue;
using Creavers.Delivery.Application.Drivers;
using Creavers.Delivery.Application.Locations;
using Creavers.Delivery.Application.Onboarding;
using Creavers.Delivery.Application.Orders;
using Microsoft.Extensions.DependencyInjection;

namespace Creavers.Delivery.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services) => services
        .AddScoped<IAuthenticationService, AuthenticationService>()
        .AddScoped<ICatalogueService, CatalogueService>()
        .AddScoped<IProductAdminService, ProductAdminService>()
        .AddScoped<IDriverService, DriverService>()
        .AddScoped<IDriverLocationService, DriverLocationService>()
        .AddScoped<ICustomerOnboardingService, CustomerOnboardingService>()
        .AddScoped<IOrderService, OrderService>();
}
