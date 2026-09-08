using System.Globalization;
using System.Net.Http.Json;
using System.Text.Json;
using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Maps;
using Creavers.Delivery.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Creavers.Delivery.Infrastructure.Maps;

public sealed partial class GoogleMapsPlatformService(
    HttpClient httpClient,
    IOptions<GoogleMapsOptions> options,
    ILogger<GoogleMapsPlatformService> logger) : IMapPlatformService
{
    private const string PlacesBaseUrl = "https://places.googleapis.com/v1/";
    private const string GeocodingBaseUrl = "https://geocode.googleapis.com/v4/geocode/";
    private const string RoutesUrl = "https://routes.googleapis.com/directions/v2:computeRoutes";
    private static readonly string[] EthiopiaRegionCodes = ["et"];
    private readonly GoogleMapsOptions _options = options.Value;

    public MapsClientConfigurationResponse GetClientConfiguration()
    {
        var webServicesEnabled = IsUsable(_options.ServerApiKey);
        var browserEnabled = IsUsable(_options.BrowserApiKey);
        return new MapsClientConfigurationResponse(
            browserEnabled,
            webServicesEnabled,
            browserEnabled ? "Google Maps Platform" : "OpenStreetMap development fallback",
            browserEnabled ? _options.BrowserApiKey : null,
            string.IsNullOrWhiteSpace(_options.MapId) ? "DEMO_MAP_ID" : _options.MapId.Trim());
    }

    public async Task<IReadOnlyList<PlaceSuggestionResponse>> AutocompleteAsync(
        string query,
        string sessionToken,
        CancellationToken cancellationToken)
    {
        ValidateQuery(query, sessionToken);
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{PlacesBaseUrl}places:autocomplete")
        {
            Content = JsonContent.Create(new
            {
                input = query.Trim(),
                sessionToken = sessionToken.Trim(),
                includedRegionCodes = EthiopiaRegionCodes,
                languageCode = "en",
                regionCode = "ET",
                locationBias = new
                {
                    rectangle = new
                    {
                        low = new { latitude = 8.7, longitude = 38.5 },
                        high = new { latitude = 9.3, longitude = 39.1 }
                    }
                }
            })
        };
        request.Headers.Add(
            "X-Goog-FieldMask",
            "suggestions.placePrediction.placeId,suggestions.placePrediction.text.text," +
            "suggestions.placePrediction.structuredFormat.mainText.text," +
            "suggestions.placePrediction.structuredFormat.secondaryText.text");

        using var document = await SendAsync(request, "Places autocomplete", cancellationToken);
        if (!document.RootElement.TryGetProperty("suggestions", out var suggestions)) return [];

        var result = new List<PlaceSuggestionResponse>();
        foreach (var suggestion in suggestions.EnumerateArray())
        {
            if (!suggestion.TryGetProperty("placePrediction", out var prediction)) continue;
            var placeId = ReadString(prediction, "placeId");
            var fullText = ReadNestedString(prediction, "text", "text");
            var mainText = ReadNestedString(prediction, "structuredFormat", "mainText", "text");
            var secondaryText = ReadNestedString(prediction, "structuredFormat", "secondaryText", "text");
            if (string.IsNullOrWhiteSpace(placeId) || string.IsNullOrWhiteSpace(fullText)) continue;
            result.Add(new PlaceSuggestionResponse(
                placeId,
                string.IsNullOrWhiteSpace(mainText) ? fullText : mainText,
                secondaryText,
                fullText));
        }

        return result.Take(6).ToList();
    }

    public async Task<MapLocationResponse?> GetPlaceAsync(
        string placeId,
        string sessionToken,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(placeId) || placeId.Length > 300)
            throw Validation("placeId", "Select a valid Google place recommendation.");
        ValidateSessionToken(sessionToken);

        var url = $"{PlacesBaseUrl}places/{Uri.EscapeDataString(placeId.Trim())}" +
            $"?sessionToken={Uri.EscapeDataString(sessionToken.Trim())}&languageCode=en&regionCode=ET";
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Add("X-Goog-FieldMask", "id,formattedAddress,location");
        using var document = await SendAsync(request, "Place details", cancellationToken);

        return ParsePlaceLocation(document.RootElement);
    }

    public async Task<MapLocationResponse?> GeocodeAsync(string address, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(address) || address.Length > 500)
            throw Validation("address", "Enter an address containing no more than 500 characters.");

        var url = $"{GeocodingBaseUrl}address/{Uri.EscapeDataString(address.Trim())}?regionCode=ET&languageCode=en";
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Add("X-Goog-FieldMask", "results.placeId,results.formattedAddress,results.location");
        using var document = await SendAsync(request, "Forward geocoding", cancellationToken);
        return ParseFirstGeocodeResult(document.RootElement);
    }

    public async Task<MapLocationResponse?> ReverseGeocodeAsync(
        double latitude,
        double longitude,
        CancellationToken cancellationToken)
    {
        ValidateCoordinates(latitude, longitude);
        var latitudeText = latitude.ToString("G17", CultureInfo.InvariantCulture);
        var longitudeText = longitude.ToString("G17", CultureInfo.InvariantCulture);
        var url = $"{GeocodingBaseUrl}location?location.latitude={latitudeText}" +
            $"&location.longitude={longitudeText}&regionCode=ET&languageCode=en";
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Add("X-Goog-FieldMask", "results.placeId,results.formattedAddress,results.location");
        using var document = await SendAsync(request, "Reverse geocoding", cancellationToken);
        return ParseFirstGeocodeResult(document.RootElement);
    }

    public async Task<DeliveryRouteResponse> ComputeRouteAsync(
        Guid orderId,
        double originLatitude,
        double originLongitude,
        double destinationLatitude,
        double destinationLongitude,
        CancellationToken cancellationToken)
    {
        ValidateCoordinates(originLatitude, originLongitude);
        ValidateCoordinates(destinationLatitude, destinationLongitude);

        using var request = new HttpRequestMessage(HttpMethod.Post, RoutesUrl)
        {
            Content = JsonContent.Create(new
            {
                origin = Waypoint(originLatitude, originLongitude),
                destination = Waypoint(destinationLatitude, destinationLongitude),
                travelMode = "DRIVE",
                routingPreference = "TRAFFIC_AWARE",
                computeAlternativeRoutes = false,
                polylineQuality = "HIGH_QUALITY",
                polylineEncoding = "ENCODED_POLYLINE",
                languageCode = "en-US",
                units = "METRIC"
            })
        };
        request.Headers.Add(
            "X-Goog-FieldMask",
            "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline");
        using var document = await SendAsync(request, "Routes", cancellationToken);

        if (!document.RootElement.TryGetProperty("routes", out var routes) || routes.GetArrayLength() == 0)
            throw new ExternalServiceUnavailableException(
                "Google Routes",
                "No drivable route is currently available for this delivery.");

        var route = routes[0];
        var distanceMeters = route.TryGetProperty("distanceMeters", out var distance)
            ? distance.GetInt32()
            : 0;
        var durationSeconds = route.TryGetProperty("duration", out var duration)
            ? ParseDurationSeconds(duration.GetString())
            : 0;
        var encodedPolyline = ReadNestedString(route, "polyline", "encodedPolyline");

        return new DeliveryRouteResponse(
            orderId,
            originLatitude,
            originLongitude,
            destinationLatitude,
            destinationLongitude,
            distanceMeters,
            durationSeconds,
            FormatDistance(distanceMeters),
            FormatDuration(durationSeconds),
            PolylineDecoder.Decode(encodedPolyline),
            "Google Routes",
            DateTimeOffset.UtcNow);
    }

    private async Task<JsonDocument> SendAsync(
        HttpRequestMessage request,
        string operation,
        CancellationToken cancellationToken)
    {
        EnsureServerConfigured();
        request.Headers.Add("X-Goog-Api-Key", _options.ServerApiKey.Trim());

        try
        {
            using var response = await httpClient.SendAsync(
                request,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                LogProviderFailure(logger, operation, (int)response.StatusCode);
                throw new ExternalServiceUnavailableException(
                    $"Google {operation}",
                    "Google Maps could not complete the location request. Try again shortly.");
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            return await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
        }
        catch (ExternalServiceUnavailableException)
        {
            throw;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception exception) when (exception is HttpRequestException or OperationCanceledException or JsonException or FormatException)
        {
            LogProviderException(logger, exception, operation);
            throw new ExternalServiceUnavailableException(
                $"Google {operation}",
                "Google Maps is temporarily unavailable. Try again shortly.",
                exception);
        }
    }

    private void EnsureServerConfigured()
    {
        if (!IsUsable(_options.ServerApiKey))
            throw new ExternalServiceUnavailableException(
                "Google Maps Platform",
                "Google Maps web services are not configured for this environment.");
    }

    private bool IsUsable(string key) =>
        _options.Enabled &&
        !string.IsNullOrWhiteSpace(key) &&
        !key.Contains("NOT_CONFIGURED", StringComparison.OrdinalIgnoreCase);

    private static object Waypoint(double latitude, double longitude) => new
    {
        location = new { latLng = new { latitude, longitude } }
    };

    private static MapLocationResponse? ParsePlaceLocation(JsonElement place)
    {
        var placeId = ReadString(place, "id");
        var address = ReadString(place, "formattedAddress");
        if (!TryReadLocation(place, out var latitude, out var longitude)) return null;
        return new MapLocationResponse(
            string.IsNullOrWhiteSpace(placeId) ? null : placeId,
            string.IsNullOrWhiteSpace(address) ? "Selected delivery point" : address,
            latitude,
            longitude);
    }

    private static MapLocationResponse? ParseFirstGeocodeResult(JsonElement root)
    {
        if (!root.TryGetProperty("results", out var results) || results.GetArrayLength() == 0) return null;
        return ParsePlaceLocation(results[0]);
    }

    private static bool TryReadLocation(JsonElement element, out double latitude, out double longitude)
    {
        latitude = 0;
        longitude = 0;
        if (!element.TryGetProperty("location", out var location) ||
            !location.TryGetProperty("latitude", out var latitudeElement) ||
            !location.TryGetProperty("longitude", out var longitudeElement)) return false;
        latitude = latitudeElement.GetDouble();
        longitude = longitudeElement.GetDouble();
        return true;
    }

    private static string ReadString(JsonElement element, string property) =>
        element.TryGetProperty(property, out var value) ? value.GetString() ?? string.Empty : string.Empty;

    private static string ReadNestedString(JsonElement element, params string[] path)
    {
        var current = element;
        foreach (var segment in path)
        {
            if (!current.TryGetProperty(segment, out current)) return string.Empty;
        }
        return current.ValueKind == JsonValueKind.String ? current.GetString() ?? string.Empty : string.Empty;
    }

    private static int ParseDurationSeconds(string? duration)
    {
        if (string.IsNullOrWhiteSpace(duration) || !duration.EndsWith('s')) return 0;
        return double.TryParse(duration[..^1], NumberStyles.Float, CultureInfo.InvariantCulture, out var seconds)
            ? (int)Math.Ceiling(seconds)
            : 0;
    }

    private static string FormatDistance(int metres) => metres >= 1_000
        ? $"{metres / 1_000d:0.0} km"
        : $"{metres} m";

    private static string FormatDuration(int seconds)
    {
        var duration = TimeSpan.FromSeconds(seconds);
        return duration.TotalHours >= 1
            ? $"{(int)duration.TotalHours} hr {duration.Minutes} min"
            : $"{Math.Max(1, (int)Math.Ceiling(duration.TotalMinutes))} min";
    }

    private static void ValidateQuery(string query, string sessionToken)
    {
        if (string.IsNullOrWhiteSpace(query) || query.Trim().Length is < 2 or > 200)
            throw Validation("query", "Enter between 2 and 200 characters to search for a location.");
        ValidateSessionToken(sessionToken);
    }

    private static void ValidateSessionToken(string sessionToken)
    {
        if (string.IsNullOrWhiteSpace(sessionToken) || sessionToken.Length > 36 ||
            sessionToken.Any(character => !(char.IsLetterOrDigit(character) || character is '-' or '_')))
            throw Validation("sessionToken", "Start a valid address-search session and try again.");
    }

    private static void ValidateCoordinates(double latitude, double longitude)
    {
        if (!double.IsFinite(latitude) || latitude is < -90 or > 90 ||
            !double.IsFinite(longitude) || longitude is < -180 or > 180)
            throw Validation("location", "Select a valid map location.");
    }

    private static ValidationException Validation(string field, string message) =>
        new(new Dictionary<string, string[]> { [field] = [message] });

    [LoggerMessage(
        EventId = 2000,
        Level = LogLevel.Warning,
        Message = "Google Maps operation {Operation} returned HTTP {StatusCode}.")]
    private static partial void LogProviderFailure(ILogger logger, string operation, int statusCode);

    [LoggerMessage(
        EventId = 2001,
        Level = LogLevel.Warning,
        Message = "Google Maps operation {Operation} failed.")]
    private static partial void LogProviderException(ILogger logger, Exception exception, string operation);
}
