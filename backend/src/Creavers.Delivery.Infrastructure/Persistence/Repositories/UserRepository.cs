using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Creavers.Delivery.Infrastructure.Persistence.Repositories;

public sealed class UserRepository(DeliveryDbContext dbContext) : IUserRepository
{
    public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken) =>
        dbContext.Users.SingleOrDefaultAsync(user => user.Email == normalizedEmail, cancellationToken);

    public Task<User?> GetByPhoneAsync(string normalizedPhoneNumber, CancellationToken cancellationToken) =>
        dbContext.Users.SingleOrDefaultAsync(user => user.PhoneNumber == normalizedPhoneNumber, cancellationToken);

    public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Users.SingleOrDefaultAsync(user => user.Id == id, cancellationToken);

    public async Task<IReadOnlyList<User>> GetActiveByRoleAsync(UserRole role, CancellationToken cancellationToken) =>
        await dbContext.Users
            .AsNoTracking()
            .Where(user => user.Role == role && user.IsActive)
            .OrderBy(user => user.DisplayName)
            .ToListAsync(cancellationToken);

    public Task AddAsync(User user, CancellationToken cancellationToken) =>
        dbContext.Users.AddAsync(user, cancellationToken).AsTask();
}
