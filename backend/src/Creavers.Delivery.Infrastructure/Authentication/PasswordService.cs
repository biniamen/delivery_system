using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace Creavers.Delivery.Infrastructure.Authentication;

public sealed class PasswordService(IPasswordHasher<User> passwordHasher) : IPasswordService
{
    public string Hash(User user, string password) => passwordHasher.HashPassword(user, password);

    public bool Verify(User user, string passwordHash, string suppliedPassword) =>
        passwordHasher.VerifyHashedPassword(user, passwordHash, suppliedPassword)
        is PasswordVerificationResult.Success or PasswordVerificationResult.SuccessRehashNeeded;
}

