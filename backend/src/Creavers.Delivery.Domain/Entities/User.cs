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

    public void SetPasswordHash(string passwordHash) => PasswordHash = passwordHash;
}

