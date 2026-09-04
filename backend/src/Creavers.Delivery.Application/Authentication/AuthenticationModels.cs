using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Authentication;

public sealed record LoginRequest(string Email, string Password);

public sealed record AuthenticatedUser(
    Guid Id,
    string Email,
    string DisplayName,
    UserRole Role,
    string? PhoneNumber = null);

public sealed record LoginResponse(string AccessToken, DateTimeOffset ExpiresAtUtc, AuthenticatedUser User);
