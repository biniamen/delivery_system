namespace Creavers.Delivery.Application.Common.Exceptions;

public sealed class NotFoundException(string message) : Exception(message)
{
}
