using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Creavers.Delivery.Infrastructure.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Creavers.Delivery.Infrastructure.Persistence;

public sealed partial class DatabaseSeeder(
    DeliveryDbContext dbContext,
    IPasswordService passwordService,
    IOptions<DemoAccountsOptions> accountOptions,
    ILogger<DatabaseSeeder> logger)
{
    private readonly DemoAccountsOptions _accounts = accountOptions.Value;

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        await dbContext.Database.MigrateAsync(cancellationToken);
        await SeedCatalogueAsync(cancellationToken);
        await SeedUsersAsync(cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task SeedCatalogueAsync(CancellationToken cancellationToken)
    {
        if (await dbContext.Categories.AnyAsync(cancellationToken)) return;

        var categorySeeds = new[]
        {
            (Name: "Fresh Produce", Slug: "fresh-produce", Products: new[]
            {
                ("Bananas", "Fresh ripe bananas", "1 kg", 95m),
                ("Tomatoes", "Locally sourced red tomatoes", "1 kg", 120m),
                ("Red Onions", "Fresh Ethiopian red onions", "1 kg", 105m),
                ("Potatoes", "All-purpose potatoes", "1 kg", 85m),
                ("Avocados", "Creamy Hass-style avocados", "4 pieces", 140m),
                ("Oranges", "Sweet seasonal oranges", "1 kg", 155m)
            }),
            (Name: "Dairy & Eggs", Slug: "dairy-eggs", Products: new[]
            {
                ("Full Cream Milk", "Pasteurized full cream milk", "1 litre", 92m),
                ("Plain Yoghurt", "Natural plain yoghurt", "500 g", 135m),
                ("Fresh Eggs", "Farm fresh medium eggs", "12 pack", 210m),
                ("Table Butter", "Creamy salted butter", "250 g", 245m),
                ("Mozzarella Cheese", "Mild mozzarella cheese", "250 g", 310m),
                ("Ayib Cottage Cheese", "Fresh Ethiopian cottage cheese", "500 g", 180m)
            }),
            (Name: "Pantry", Slug: "pantry", Products: new[]
            {
                ("Teff Flour", "White teff flour for injera", "5 kg", 720m),
                ("Basmati Rice", "Long-grain basmati rice", "5 kg", 980m),
                ("Wheat Pasta", "Durum wheat spaghetti", "500 g", 115m),
                ("Shiro Powder", "Seasoned chickpea flour blend", "1 kg", 260m),
                ("Red Lentils", "Cleaned split red lentils", "1 kg", 225m),
                ("Sunflower Oil", "Refined cooking oil", "3 litres", 690m)
            }),
            (Name: "Meat & Poultry", Slug: "meat-poultry", Products: new[]
            {
                ("Beef Cubes", "Fresh boneless beef cubes", "1 kg", 980m),
                ("Minced Beef", "Fresh lean minced beef", "500 g", 520m),
                ("Whole Chicken", "Chilled whole chicken", "1.2 kg", 760m),
                ("Chicken Breast", "Boneless chicken breast", "500 g", 510m),
                ("Lamb Cubes", "Fresh lamb stew cubes", "1 kg", 1150m),
                ("Beef Sausages", "Mild beef sausages", "500 g", 430m)
            }),
            (Name: "Beverages", Slug: "beverages", Products: new[]
            {
                ("Natural Mineral Water", "Still mineral water", "6 x 1 litre", 210m),
                ("Mango Juice", "Mango fruit drink", "1 litre", 165m),
                ("Orange Juice", "Orange fruit drink", "1 litre", 175m),
                ("Ethiopian Coffee", "Medium roast ground coffee", "500 g", 480m),
                ("Black Tea", "Ethiopian black tea bags", "100 pack", 290m),
                ("Sparkling Water", "Plain sparkling water", "6 x 500 ml", 260m)
            }),
            (Name: "Household", Slug: "household", Products: new[]
            {
                ("Dishwashing Liquid", "Lemon dishwashing liquid", "750 ml", 185m),
                ("Laundry Detergent", "Machine and hand-wash powder", "2 kg", 440m),
                ("Toilet Tissue", "Two-ply toilet tissue", "10 rolls", 330m),
                ("Kitchen Towels", "Absorbent paper kitchen towels", "2 rolls", 145m),
                ("Multipurpose Cleaner", "Fresh-scent surface cleaner", "1 litre", 220m),
                ("Refuse Bags", "Strong medium refuse bags", "20 pack", 195m)
            })
        };

        for (var categoryIndex = 0; categoryIndex < categorySeeds.Length; categoryIndex++)
        {
            var seed = categorySeeds[categoryIndex];
            var categoryId = StableGuid($"category:{seed.Slug}");
            var category = new Category(categoryId, seed.Name, seed.Slug, categoryIndex + 1);
            await dbContext.Categories.AddAsync(category, cancellationToken);

            foreach (var product in seed.Products)
            {
                var productSlug = Slugify(product.Item1);
                await dbContext.Products.AddAsync(new Product(
                    StableGuid($"product:{seed.Slug}:{productSlug}"),
                    categoryId,
                    product.Item1,
                    product.Item2,
                    product.Item3,
                    product.Item4,
                    $"/assets/products/{productSlug}.webp",
                    40), cancellationToken);
            }
        }
    }

    private async Task SeedUsersAsync(CancellationToken cancellationToken)
    {
        var accounts = new[]
        {
            (_accounts.CustomerEmail, _accounts.CustomerPassword, "Demo Customer", UserRole.Customer),
            (_accounts.DispatcherEmail, _accounts.DispatcherPassword, "Demo Dispatcher", UserRole.Dispatcher),
            (_accounts.DriverEmail, _accounts.DriverPassword, "Demo Driver", UserRole.Driver),
            ("driver2@demo.creavers.local", _accounts.DriverPassword, "Demo Driver 2", UserRole.Driver),
            ("driver3@demo.creavers.local", _accounts.DriverPassword, "Demo Driver 3", UserRole.Driver),
            (_accounts.StoreAdminEmail, _accounts.StoreAdminPassword, "Supermarket Admin", UserRole.StoreAdmin)
        };

        foreach (var account in accounts)
        {
            if (await dbContext.Users.AnyAsync(user => user.Email == account.Item1, cancellationToken)) continue;
            if (string.IsNullOrWhiteSpace(account.Item2))
            {
                LogDemoAccountSkipped(logger, account.Item1);
                continue;
            }

            var user = new User(StableGuid($"user:{account.Item1}"), account.Item1, account.Item3, account.Item4);
            user.SetPasswordHash(passwordService.Hash(user, account.Item2));
            await dbContext.Users.AddAsync(user, cancellationToken);
        }
    }

    private static Guid StableGuid(string value)
    {
        var hash = System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(value));
        return new Guid(hash.AsSpan(0, 16));
    }

    private static string Slugify(string value) => string.Join(
        '-',
        value.ToLowerInvariant().Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));

    [LoggerMessage(
        EventId = 1001,
        Level = LogLevel.Warning,
        Message = "Skipping demo account {Email}: no password was configured.")]
    private static partial void LogDemoAccountSkipped(ILogger logger, string email);
}
