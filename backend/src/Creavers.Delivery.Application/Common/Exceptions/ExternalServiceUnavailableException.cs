namespace Creavers.Delivery.Application.Common.Exceptions;

public sealed class ExternalServiceUnavailableException(string service, string message, Exception? innerException = null)
    : Exception(message, innerException)
{
    public string Service { get; } = service;
}
