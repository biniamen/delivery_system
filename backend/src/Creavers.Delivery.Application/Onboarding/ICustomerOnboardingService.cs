namespace Creavers.Delivery.Application.Onboarding;

public interface ICustomerOnboardingService
{
    Task<CustomerOtpChallengeResponse> RequestOtpAsync(
        RequestCustomerOtpRequest request,
        CancellationToken cancellationToken);
    Task<CustomerOtpVerificationResponse> VerifyOtpAsync(
        VerifyCustomerOtpRequest request,
        CancellationToken cancellationToken);
    Task<Authentication.LoginResponse> RegisterAsync(
        RegisterCustomerRequest request,
        CancellationToken cancellationToken);
}

public interface ICustomerOnboardingSettings
{
    bool Enabled { get; }
    string DevelopmentOtpCode { get; }
    bool ExposeDevelopmentCode { get; }
    TimeSpan OtpLifetime { get; }
}

public interface IOtpChallengeStore
{
    OtpChallengeState? FindChallenge(Guid challengeId);
    void SaveChallenge(OtpChallengeState challenge);
    void RemoveChallenge(Guid challengeId);
}
