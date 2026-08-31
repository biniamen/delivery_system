namespace Creavers.Delivery.Application.Common.Exceptions;

public sealed class ConflictException(string message) : Exception(message)
{
}
