using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Repositories;

public interface IUserRepository
{
    Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken);
    Task<User?> GetByPhoneAsync(string normalizedPhoneNumber, CancellationToken cancellationToken);
    Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<IReadOnlyList<User>> GetByRoleAsync(UserRole role, CancellationToken cancellationToken);
    Task<IReadOnlyList<User>> GetActiveByRoleAsync(UserRole role, CancellationToken cancellationToken);
    Task AddAsync(User user, CancellationToken cancellationToken);
}
