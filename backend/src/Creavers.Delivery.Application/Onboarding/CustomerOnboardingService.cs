using System.Text.RegularExpressions;
using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Onboarding;

public sealed partial class CustomerOnboardingService(
    IUserRepository users,
    IOtpChallengeStore challenges,
    ICustomerOnboardingSettings settings,
    IPasswordService passwords,
    ITokenIssuer tokenIssuer,
    IUnitOfWork unitOfWork,
    IClock clock) : ICustomerOnboardingService
{
    public Task<CustomerOtpChallengeResponse> RequestOtpAsync(
        RequestCustomerOtpRequest request,
        CancellationToken cancellationToken)
    {
        if (!settings.Enabled)
            throw new ConflictException("Phone onboarding is not enabled in this environment.");

        var phoneNumber = NormalizePhone(request.PhoneNumber);
        var challenge = new OtpChallengeState(
            Guid.NewGuid(),
            phoneNumber,
            clock.UtcNow.Add(settings.OtpLifetime),
            false);
        challenges.SaveChallenge(challenge);

        return Task.FromResult(new CustomerOtpChallengeResponse(
            challenge.Id,
            Mask(phoneNumber),
            challenge.ExpiresAtUtc,
            settings.ExposeDevelopmentCode ? settings.DevelopmentOtpCode : null));
    }

    public async Task<CustomerOtpVerificationResponse> VerifyOtpAsync(
        VerifyCustomerOtpRequest request,
        CancellationToken cancellationToken)
    {
        var phoneNumber = NormalizePhone(request.PhoneNumber);
        var challenge = GetValidChallenge(request.ChallengeId, phoneNumber);
        if (!string.Equals(request.OtpCode?.Trim(), settings.DevelopmentOtpCode, StringComparison.Ordinal))
            throw OtpError("The verification code is incorrect.");

        var existing = await users.GetByPhoneAsync(phoneNumber, cancellationToken);
        if (existing is not null)
        {
            challenges.RemoveChallenge(challenge.Id);
            if (!existing.IsActive || existing.Role != UserRole.Customer || !existing.IsPhoneVerified)
                throw new ConflictException("This phone number cannot be used for customer onboarding.");
            return new CustomerOtpVerificationResponse(false, null, tokenIssuer.Issue(existing));
        }

        challenges.SaveChallenge(challenge with { IsVerified = true });
        return new CustomerOtpVerificationResponse(true, challenge.Id, null);
    }

    public async Task<LoginResponse> RegisterAsync(
        RegisterCustomerRequest request,
        CancellationToken cancellationToken)
    {
        var phoneNumber = NormalizePhone(request.PhoneNumber);
        var challenge = GetValidChallenge(request.VerifiedChallengeId, phoneNumber);
        if (!challenge.IsVerified) throw OtpError("Verify the phone number before creating the profile.");
        ValidateProfile(request.FullName, request.DateOfBirth);

        if (await users.GetByPhoneAsync(phoneNumber, cancellationToken) is not null)
            throw new ConflictException("A customer account already exists for this phone number.");

        var digits = phoneNumber[1..];
        var user = new User(
            Guid.NewGuid(),
            $"customer-{digits}@phone.creavers.local",
            request.FullName,
            UserRole.Customer);
        user.CompleteCustomerProfile(phoneNumber, request.FullName, request.DateOfBirth);
        user.SetPasswordHash(passwords.Hash(user, Guid.NewGuid().ToString("N")));
        await users.AddAsync(user, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        challenges.RemoveChallenge(challenge.Id);
        return tokenIssuer.Issue(user);
    }

    private OtpChallengeState GetValidChallenge(Guid challengeId, string phoneNumber)
    {
        var challenge = challenges.FindChallenge(challengeId);
        if (challenge is null || challenge.PhoneNumber != phoneNumber || challenge.ExpiresAtUtc <= clock.UtcNow)
        {
            if (challenge is not null) challenges.RemoveChallenge(challenge.Id);
            throw OtpError("The verification session has expired. Request a new code.");
        }
        return challenge;
    }

    private static string NormalizePhone(string? value)
    {
        var compact = (value ?? string.Empty).Replace(" ", string.Empty).Replace("-", string.Empty);
        if (compact.StartsWith("09", StringComparison.Ordinal)) compact = $"+251{compact[1..]}";
        else if (compact.Length == 9 && compact.StartsWith('9')) compact = $"+251{compact}";
        else if (compact.StartsWith("251", StringComparison.Ordinal)) compact = $"+{compact}";

        if (!PhoneRegex().IsMatch(compact))
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["phoneNumber"] = ["Enter a valid Ethiopian mobile number, for example +251911234567."]
            });
        return compact;
    }

    private void ValidateProfile(string? fullName, DateOnly dateOfBirth)
    {
        var errors = new Dictionary<string, string[]>();
        if (string.IsNullOrWhiteSpace(fullName) || fullName.Trim().Length is < 2 or > 100)
            errors["fullName"] = ["Full name must contain 2 to 100 characters."];
        var today = DateOnly.FromDateTime(clock.UtcNow.UtcDateTime);
        if (dateOfBirth > today || dateOfBirth < today.AddYears(-120))
            errors["dateOfBirth"] = ["Enter a valid date of birth."];
        if (errors.Count > 0) throw new ValidationException(errors);
    }

    private static ValidationException OtpError(string message) => new(
        new Dictionary<string, string[]> { ["otpCode"] = [message] });

    private static string Mask(string phoneNumber) => $"{phoneNumber[..6]} ** *** {phoneNumber[^3..]}";

    [GeneratedRegex(@"^\+2519\d{8}$", RegexOptions.Compiled)]
    private static partial Regex PhoneRegex();
}
