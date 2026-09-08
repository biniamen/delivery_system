using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Domain.Entities;

public sealed class User
{
    private User() { }

    public User(Guid id, string email, string displayName, UserRole role)
    {
        Id = id;
        Email = email.Trim().ToLowerInvariant();
        DisplayName = displayName.Trim();
        Role = role;
    }

    public Guid Id { get; private set; }
    public string Email { get; private set; } = string.Empty;
    public string DisplayName { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public UserRole Role { get; private set; }
    public bool IsActive { get; private set; } = true;
    public string? PhoneNumber { get; private set; }
    public DateOnly? DateOfBirth { get; private set; }
    public bool IsPhoneVerified { get; private set; }

    public void SetPasswordHash(string passwordHash) => PasswordHash = passwordHash;

    public void CompleteCustomerProfile(string phoneNumber, string displayName, DateOnly dateOfBirth)
    {
        if (Role != UserRole.Customer)
            throw new InvalidOperationException("Only customer accounts can have an onboarding profile.");

        PhoneNumber = phoneNumber.Trim();
        DisplayName = displayName.Trim();
        DateOfBirth = dateOfBirth;
        IsPhoneVerified = true;
    }
}
