namespace Creavers.Delivery.Infrastructure.Configuration;

public sealed class DemoAccountsOptions
{
    public const string SectionName = "DemoAccounts";

    public string CustomerEmail { get; init; } = "customer@demo.creavers.local";
    public string CustomerPassword { get; init; } = string.Empty;
    public string DispatcherEmail { get; init; } = "dispatcher@demo.creavers.local";
    public string DispatcherPassword { get; init; } = string.Empty;
    public string DriverEmail { get; init; } = "driver@demo.creavers.local";
    public string DriverPassword { get; init; } = string.Empty;
    public string StoreAdminEmail { get; init; } = "storeadmin@demo.creavers.local";
    public string StoreAdminPassword { get; init; } = string.Empty;
}
