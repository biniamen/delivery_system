using Creavers.Delivery.Application.Repositories;

namespace Creavers.Delivery.Application.Authentication;

public sealed class AuthenticationService(
    IUserRepository users,
    IPasswordService passwords,
    ITokenIssuer tokenIssuer) : IAuthenticationService
{
    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password)) return null;

        var user = await users.GetByEmailAsync(request.Email.Trim().ToLowerInvariant(), cancellationToken);
        if (user is null || !user.IsActive || !passwords.Verify(user, user.PasswordHash, request.Password)) return null;

        return tokenIssuer.Issue(user);
    }
}

