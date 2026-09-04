using Creavers.Delivery.Application.Authentication;

namespace Creavers.Delivery.Application.Onboarding;

public sealed record RequestCustomerOtpRequest(string PhoneNumber);

public sealed record CustomerOtpChallengeResponse(
    Guid ChallengeId,
    string MaskedPhoneNumber,
    DateTimeOffset ExpiresAtUtc,
    string? DevelopmentCode);

public sealed record VerifyCustomerOtpRequest(Guid ChallengeId, string PhoneNumber, string OtpCode);

public sealed record CustomerOtpVerificationResponse(
    bool RequiresProfile,
    Guid? VerifiedChallengeId,
    LoginResponse? Session);

public sealed record RegisterCustomerRequest(
    Guid VerifiedChallengeId,
    string PhoneNumber,
    string FullName,
    DateOnly DateOfBirth);

public sealed record OtpChallengeState(
    Guid Id,
    string PhoneNumber,
    DateTimeOffset ExpiresAtUtc,
    bool IsVerified);
