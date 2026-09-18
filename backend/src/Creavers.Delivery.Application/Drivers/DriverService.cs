using System.Net.Mail;
using System.Text.RegularExpressions;
using Creavers.Delivery.Application.Authentication;
using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Application.Common.Interfaces;
using Creavers.Delivery.Application.Repositories;
using Creavers.Delivery.Domain.Entities;
using Creavers.Delivery.Domain.Enums;

namespace Creavers.Delivery.Application.Drivers;

public sealed partial class DriverService(
    IUserRepository users,
    IOrderRepository orders,
    IPasswordService passwords,
    IUnitOfWork unitOfWork) : IDriverService
{
    public async Task<IReadOnlyList<DriverAccountResponse>> ListAsync(CancellationToken cancellationToken) =>
        (await users.GetByRoleAsync(UserRole.Driver, cancellationToken))
        .Select(Map)
        .ToList();

    public async Task<IReadOnlyList<DriverAccountResponse>> GetAvailableAsync(
        Guid? forOrderId,
        CancellationToken cancellationToken)
    {
        var drivers = await users.GetActiveByRoleAsync(UserRole.Driver, cancellationToken);
        if (drivers.Count == 0) return [];

        var activeOrders = await orders.ListActiveByDriversAsync(
            drivers.Select(driver => driver.Id).ToArray(),
            cancellationToken);
        var unavailableDriverIds = activeOrders
            .Where(order => !forOrderId.HasValue || order.Id != forOrderId.Value)
            .Select(order => order.AssignedDriverId)
            .OfType<Guid>()
            .ToHashSet();

        return drivers
            .Where(driver => !unavailableDriverIds.Contains(driver.Id))
            .Select(Map)
            .ToList();
    }

    public async Task<DriverAccountResponse> CreateAsync(
        CreateDriverRequest request,
        CancellationToken cancellationToken)
    {
        var (displayName, email, phoneNumber, temporaryPassword) = ValidateAndNormalize(request);
        if (await users.GetByEmailAsync(email, cancellationToken) is not null)
            throw new ConflictException("An account already exists with this email address.");
        if (await users.GetByPhoneAsync(phoneNumber, cancellationToken) is not null)
            throw new ConflictException("An account already exists with this phone number.");

        var driver = new User(Guid.NewGuid(), email, displayName, UserRole.Driver);
        driver.CompleteDriverProfile(phoneNumber);
        driver.SetPasswordHash(passwords.Hash(driver, temporaryPassword));
        await users.AddAsync(driver, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(driver);
    }

    public async Task<DriverAccountResponse> SetActiveAsync(
        Guid driverId,
        SetDriverStatusRequest request,
        CancellationToken cancellationToken)
    {
        var driver = await users.GetByIdAsync(driverId, cancellationToken);
        if (driver is null || driver.Role != UserRole.Driver)
            throw new NotFoundException($"Driver '{driverId}' was not found.");
        if (driver.IsActive == request.IsActive) return Map(driver);

        if (!request.IsActive && await orders.HasActiveAssignmentAsync(driverId, null, cancellationToken))
            throw new ConflictException("Complete or reassign the driver's active delivery before deactivating the account.");

        driver.SetActive(request.IsActive);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        return Map(driver);
    }

    private static (string DisplayName, string Email, string PhoneNumber, string TemporaryPassword) ValidateAndNormalize(
        CreateDriverRequest request)
    {
        var displayName = request.DisplayName?.Trim() ?? string.Empty;
        var email = request.Email?.Trim().ToLowerInvariant() ?? string.Empty;
        var phoneNumber = NormalizePhone(request.PhoneNumber);
        var temporaryPassword = request.TemporaryPassword ?? string.Empty;
        var errors = new Dictionary<string, string[]>();

        if (displayName.Length is < 2 or > 100)
            errors["displayName"] = ["Driver name must contain 2 to 100 characters."];
        if (email.Length > 254 || !MailAddress.TryCreate(email, out var parsedEmail) || parsedEmail.Address != email)
            errors["email"] = ["Enter a valid email address."];
        if (temporaryPassword.Length is < 10 or > 100 ||
            !temporaryPassword.Any(char.IsUpper) ||
            !temporaryPassword.Any(char.IsLower) ||
            !temporaryPassword.Any(char.IsDigit) ||
            temporaryPassword.All(char.IsLetterOrDigit))
            errors["temporaryPassword"] = ["Use 10 to 100 characters with uppercase, lowercase, number and symbol."];

        if (errors.Count > 0) throw new ValidationException(errors);
        return (displayName, email, phoneNumber, temporaryPassword);
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

    private static DriverAccountResponse Map(User driver) => new(
        driver.Id,
        driver.Email,
        driver.DisplayName,
        driver.Role,
        driver.PhoneNumber,
        driver.IsActive);

    [GeneratedRegex(@"^\+2519\d{8}$", RegexOptions.Compiled)]
    private static partial Regex PhoneRegex();
}
