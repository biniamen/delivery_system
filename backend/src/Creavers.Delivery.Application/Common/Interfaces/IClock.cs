namespace Creavers.Delivery.Application.Common.Interfaces;

public interface IClock
{
    DateTimeOffset UtcNow { get; }
}

