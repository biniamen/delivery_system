using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Onboarding;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;
using Creavers.Delivery.Infrastructure.Authentication;
using Xunit;

namespace Creavers.Delivery.UnitTests;

public sealed class CustomerOnboardingTests
{
    private static readonly DateTimeOffset Now = new(2026, 9, 4, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task RequestOtpNormalizesEthiopianPhoneAndReturnsDevelopmentCode()
    {
        var service = CreateService(out _, out _);

        var challenge = await service.RequestOtpAsync(new RequestCustomerOtpRequest("0911 234-567"), default);

        Assert.Equal("+25191 ** *** 567", challenge.MaskedPhoneNumber);
        Assert.Equal("246810", challenge.DevelopmentCode);
        Assert.Equal(Now.AddMinutes(5), challenge.ExpiresAtUtc);
    }

    [Fact]
    public async Task VerifyOtpRejectsIncorrectDevelopmentCode()
    {
        var service = CreateService(out _, out _);
        var challenge = await service.RequestOtpAsync(new RequestCustomerOtpRequest("0911234567"), default);

        var action = () => service.VerifyOtpAsync(
            new VerifyCustomerOtpRequest(challenge.ChallengeId, "+251911234567", "000000"),
            default);

        await Assert.ThrowsAsync<ValidationException>(action);
    }

    [Fact]
    public async Task VerifiedPhoneCanCreateCustomerProfileAndReceiveSession()
    {
        var service = CreateService(out var repository, out var unitOfWork);
        var challenge = await service.RequestOtpAsync(new RequestCustomerOtpRequest("0911234567"), default);
        var verification = await service.VerifyOtpAsync(
            new VerifyCustomerOtpRequest(challenge.ChallengeId, "0911234567", "246810"),
            default);

        var session = await service.RegisterAsync(
            new RegisterCustomerRequest(
                verification.VerifiedChallengeId!.Value,
                "+251911234567",
                "Selam Tesfaye",
                new DateOnly(1996, 4, 18)),
            default);

        var user = Assert.Single(repository.Users);
        Assert.Equal(UserRole.Customer, user.Role);
        Assert.Equal("+251911234567", user.PhoneNumber);
        Assert.True(user.IsPhoneVerified);
        Assert.Equal("Selam Tesfaye", session.User.DisplayName);
        Assert.Equal("+251911234567", session.User.PhoneNumber);
        Assert.Equal(1, unitOfWork.SaveCount);
    }

    private static CustomerOnboardingService CreateService(
        out InMemoryUserRepository repository,
        out RecordingUnitOfWork unitOfWork)
    {
        repository = new InMemoryUserRepository();
        unitOfWork = new RecordingUnitOfWork();
        return new CustomerOnboardingService(
            repository,
            new MemoryOtpChallengeStore(),
            new TestSettings(),
            new TestPasswordService(),
            new TestTokenIssuer(),
            unitOfWork,
            new FixedClock());
    }

    private sealed class TestSettings : ICustomerOnboardingSettings
    {
        public bool Enabled => true;
        public string DevelopmentOtpCode => "246810";
        public bool ExposeDevelopmentCode => true;
        public TimeSpan OtpLifetime => TimeSpan.FromMinutes(5);
    }

    private sealed class FixedClock : IClock
    {
        public DateTimeOffset UtcNow => Now;
    }

    private sealed class TestPasswordService : IPasswordService
    {
        public string Hash(User user, string password) => $"hashed:{password}";
        public bool Verify(User user, string passwordHash, string suppliedPassword) => false;
    }

    private sealed class TestTokenIssuer : ITokenIssuer
    {
        public LoginResponse Issue(User user) => new(
            "test-token",
            Now.AddHours(1),
            new AuthenticatedUser(user.Id, user.Email, user.DisplayName, user.Role, user.PhoneNumber));
    }

    private sealed class RecordingUnitOfWork : IUnitOfWork
    {
        public int SaveCount { get; private set; }

        public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            SaveCount++;
            return Task.FromResult(1);
        }
    }

    private sealed class InMemoryUserRepository : IUserRepository
    {
        public List<User> Users { get; } = [];

        public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken) =>
            Task.FromResult(Users.SingleOrDefault(user => user.Email == normalizedEmail));

        public Task<User?> GetByPhoneAsync(string normalizedPhoneNumber, CancellationToken cancellationToken) =>
            Task.FromResult(Users.SingleOrDefault(user => user.PhoneNumber == normalizedPhoneNumber));

        public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(Users.SingleOrDefault(user => user.Id == id));

        public Task<IReadOnlyList<User>> GetActiveByRoleAsync(UserRole role, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<User>>(
                Users.Where(user => user.Role == role && user.IsActive).ToList());

        public Task AddAsync(User user, CancellationToken cancellationToken)
        {
            Users.Add(user);
            return Task.CompletedTask;
        }
    }
}
