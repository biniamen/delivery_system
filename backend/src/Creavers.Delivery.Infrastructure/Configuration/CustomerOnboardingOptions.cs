using Creavers.Delivery.Application.Onboarding;

namespace Creavers.Delivery.Infrastructure.Configuration;

public sealed class CustomerOnboardingOptions : ICustomerOnboardingSettings
{
    public const string SectionName = "CustomerOnboarding";

    public bool Enabled { get; init; }
    public string DevelopmentOtpCode { get; init; } = string.Empty;
    public bool ExposeDevelopmentCode { get; init; }
    public int OtpLifetimeMinutes { get; init; } = 5;
    public TimeSpan OtpLifetime => TimeSpan.FromMinutes(OtpLifetimeMinutes);
}
