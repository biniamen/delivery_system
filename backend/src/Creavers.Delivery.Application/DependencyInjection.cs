using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Catalogue;
using Creavers.Delivery.Application.Drivers;
using Creavers.Delivery.Application.Locations;
using Creavers.Delivery.Application.Orders;
using Microsoft.Extensions.DependencyInjection;

namespace Creavers.Delivery.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services) => services
        .AddScoped<IAuthenticationService, AuthenticationService>()
        .AddScoped<ICatalogueService, CatalogueService>()
        .AddScoped<IDriverService, DriverService>()
        .AddScoped<IDriverLocationService, DriverLocationService>()
        .AddScoped<IOrderService, OrderService>();
}
