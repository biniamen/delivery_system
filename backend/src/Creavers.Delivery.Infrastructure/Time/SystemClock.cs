using Creavers.Delivery.Application.Common.Interfaces;

namespace Creavers.Delivery.Infrastructure.Time;

public sealed class SystemClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}

