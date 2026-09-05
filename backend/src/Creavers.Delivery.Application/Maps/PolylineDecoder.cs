namespace Creavers.Delivery.Application.Maps;

public static class PolylineDecoder
{
    public static IReadOnlyList<RoutePointResponse> Decode(string encoded)
    {
        if (string.IsNullOrWhiteSpace(encoded)) return [];

        var points = new List<RoutePointResponse>();
        var latitude = 0;
        var longitude = 0;
        var index = 0;

        while (index < encoded.Length)
        {
            latitude += DecodeValue(encoded, ref index);
            longitude += DecodeValue(encoded, ref index);
            points.Add(new RoutePointResponse(latitude / 100_000d, longitude / 100_000d));
        }

        return points;
    }

    private static int DecodeValue(string encoded, ref int index)
    {
        var result = 0;
        var shift = 0;
        int value;

        do
        {
            if (index >= encoded.Length)
                throw new FormatException("The encoded route polyline is incomplete.");

            value = encoded[index++] - 63;
            result |= (value & 0x1F) << shift;
            shift += 5;
        }
        while (value >= 0x20);

        return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    }
}
