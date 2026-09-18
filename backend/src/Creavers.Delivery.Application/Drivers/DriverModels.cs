using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Drivers;

public sealed record DriverAccountResponse(
    Guid Id,
    string Email,
    string DisplayName,
    UserRole Role,
    string? PhoneNumber,
    bool IsActive);

public sealed record CreateDriverRequest(
    string DisplayName,
    string Email,
    string PhoneNumber,
    string TemporaryPassword);

public sealed record SetDriverStatusRequest(bool IsActive);
