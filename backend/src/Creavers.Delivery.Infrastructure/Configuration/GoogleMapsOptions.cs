namespace Creavers.Delivery.Infrastructure.Configuration;

public sealed class GoogleMapsOptions
{
    public const string SectionName = "GoogleMaps";

    public bool Enabled { get; init; }
    public string ServerApiKey { get; init; } = string.Empty;
    public string BrowserApiKey { get; init; } = string.Empty;
    public string MapId { get; init; } = "DEMO_MAP_ID";
}
