using Creavers.Delivery.Application.Maps;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class MapTests
{
    [Fact]
    public void GoogleEncodedPolylineDecodesIntoRoutePoints()
    {
        var points = PolylineDecoder.Decode("_p~iF~ps|U_ulLnnqC_mqNvxq`@");

        Assert.Equal(3, points.Count);
        Assert.Equal(38.5, points[0].Latitude, 5);
        Assert.Equal(-120.2, points[0].Longitude, 5);
        Assert.Equal(43.252, points[2].Latitude, 5);
        Assert.Equal(-126.453, points[2].Longitude, 5);
    }

    [Fact]
    public void EmptyPolylineReturnsNoPoints()
    {
        Assert.Empty(PolylineDecoder.Decode(string.Empty));
    }

    [Fact]
    public void IncompletePolylineIsRejected()
    {
        Assert.Throws<FormatException>(() => PolylineDecoder.Decode("~"));
    }
}
