using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Onboarding;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Creavers.Delivery.Api.Controllers;

[ApiController]
[AllowAnonymous]
[EnableRateLimiting("customer-otp")]
[Route("api/v1/customer-onboarding")]
public sealed class CustomerOnboardingController(ICustomerOnboardingService onboarding) : ControllerBase
{
    [HttpPost("otp")]
    [ProducesResponseType<CustomerOtpChallengeResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<CustomerOtpChallengeResponse>> RequestOtp(
        RequestCustomerOtpRequest request,
        CancellationToken cancellationToken) =>
        Ok(await onboarding.RequestOtpAsync(request, cancellationToken));

    [HttpPost("otp/verify")]
    [ProducesResponseType<CustomerOtpVerificationResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<CustomerOtpVerificationResponse>> VerifyOtp(
        VerifyCustomerOtpRequest request,
        CancellationToken cancellationToken) =>
        Ok(await onboarding.VerifyOtpAsync(request, cancellationToken));

    [HttpPost("register")]
    [ProducesResponseType<LoginResponse>(StatusCodes.Status201Created)]
    public async Task<ActionResult<LoginResponse>> Register(
        RegisterCustomerRequest request,
        CancellationToken cancellationToken) =>
        StatusCode(
            StatusCodes.Status201Created,
            await onboarding.RegisterAsync(request, cancellationToken));
}
