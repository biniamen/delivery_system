using System.Text;
using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Maps;
using Creavers.Delivery.Application.Onboarding;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Infrastructure.Authentication;
using Creavers.Delivery.Infrastructure.Configuration;
using Creavers.Delivery.Infrastructure.Maps;
using Creavers.Delivery.Infrastructure.Persistence;
using Creavers.Delivery.Infrastructure.Persistence.Repositories;
using Creavers.Delivery.Infrastructure.Time;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Creavers.Delivery.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Postgres");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("ConnectionStrings:Postgres is required.");

        services
            .AddOptions<JwtOptions>()
            .Bind(configuration.GetSection(JwtOptions.SectionName))
            .Validate(options => options.SigningKey.Length >= 32, "JWT signing key must contain at least 32 characters.")
            .Validate(options => !string.IsNullOrWhiteSpace(options.Issuer), "JWT issuer is required.")
            .Validate(options => !string.IsNullOrWhiteSpace(options.Audience), "JWT audience is required.")
            .ValidateOnStart();
        services.AddOptions<DemoAccountsOptions>()
            .Bind(configuration.GetSection(DemoAccountsOptions.SectionName));
        services.AddOptions<CustomerOnboardingOptions>()
            .Bind(configuration.GetSection(CustomerOnboardingOptions.SectionName))
            .Validate(
                options => !options.Enabled ||
                    (options.DevelopmentOtpCode.Length == 6 && options.DevelopmentOtpCode.All(char.IsDigit)),
                "Customer onboarding OTP code must contain exactly six digits.")
            .Validate(options => options.OtpLifetimeMinutes is >= 1 and <= 15, "OTP lifetime must be 1 to 15 minutes.")
            .ValidateOnStart();
        services.AddOptions<GoogleMapsOptions>()
            .Bind(configuration.GetSection(GoogleMapsOptions.SectionName))
            .Validate(
                options => !options.Enabled || !string.IsNullOrWhiteSpace(options.ServerApiKey),
                "GoogleMaps:ServerApiKey is required when Google Maps is enabled.")
            .Validate(
                options => !options.Enabled || !string.IsNullOrWhiteSpace(options.BrowserApiKey),
                "GoogleMaps:BrowserApiKey is required when Google Maps is enabled.")
            .ValidateOnStart();

        services.AddDbContext<DeliveryDbContext>(options => options.UseNpgsql(connectionString));
        services.AddScoped<IUnitOfWork>(provider => provider.GetRequiredService<DeliveryDbContext>());
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<ICatalogueRepository, CatalogueRepository>();
        services.AddScoped<IDriverLocationRepository, DriverLocationRepository>();
        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddHttpClient<IMapPlatformService, GoogleMapsPlatformService>(client =>
        {
            client.Timeout = TimeSpan.FromSeconds(10);
            client.DefaultRequestHeaders.UserAgent.ParseAdd("Creavers-Delivery/1.0");
        });
        services.AddScoped<
            IPasswordHasher<Creavers.Delivery.Domain.Entities.User>,
            PasswordHasher<Creavers.Delivery.Domain.Entities.User>>();
        services.AddScoped<IPasswordService, PasswordService>();
        services.AddScoped<ITokenIssuer, JwtTokenIssuer>();
        services.AddSingleton<IOtpChallengeStore, MemoryOtpChallengeStore>();
        services.AddSingleton<ICustomerOnboardingSettings>(provider =>
            provider.GetRequiredService<IOptions<CustomerOnboardingOptions>>().Value);
        services.AddSingleton<IClock, SystemClock>();
        services.AddScoped<DatabaseSeeder>();

        var jwt = configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()
            ?? throw new InvalidOperationException("JWT configuration is required.");
        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwt.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwt.Audience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SigningKey)),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromSeconds(30)
                };
            });

        services.AddAuthorizationBuilder()
            .AddPolicy("DispatcherOnly", policy => policy.RequireRole("Dispatcher"))
            .AddPolicy("CustomerOnly", policy => policy.RequireRole("Customer"))
            .AddPolicy("DriverOnly", policy => policy.RequireRole("Driver"))
            .AddPolicy("StoreAdminOnly", policy => policy.RequireRole("StoreAdmin"));

        return services;
    }
}
