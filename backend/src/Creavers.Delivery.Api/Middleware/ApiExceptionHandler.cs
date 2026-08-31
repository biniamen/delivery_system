using Creavers.Delivery.Application.Common.Exceptions;
using Creavers.Delivery.Domain.Exceptions;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace Creavers.Delivery.Api.Middleware;

public sealed partial class ApiExceptionHandler(
    IProblemDetailsService problemDetailsService,
    ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (status, title, detail, extensions) = exception switch
        {
            ValidationException validation => (
                StatusCodes.Status400BadRequest,
                "Validation failed",
                "Check the submitted values and try again.",
                new Dictionary<string, object?> { ["errors"] = validation.Errors }),
            NotFoundException => (
                StatusCodes.Status404NotFound,
                "Resource not found",
                exception.Message,
                new Dictionary<string, object?>()),
            ConflictException or DomainRuleException => (
                StatusCodes.Status409Conflict,
                "Request conflicts with the current state",
                exception.Message,
                new Dictionary<string, object?>()),
            _ => (
                StatusCodes.Status500InternalServerError,
                "Unexpected server error",
                "The request could not be completed. Use the trace ID when contacting support.",
                new Dictionary<string, object?>())
        };

        if (status == StatusCodes.Status500InternalServerError)
            LogUnhandledRequestFailure(logger, exception, httpContext.TraceIdentifier);
        else
            LogHandledRequestFailure(logger, exception, httpContext.TraceIdentifier);

        extensions["traceId"] = httpContext.TraceIdentifier;
        httpContext.Response.StatusCode = status;
        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            ProblemDetails = new ProblemDetails
            {
                Status = status,
                Title = title,
                Detail = detail,
                Extensions = extensions
            },
            Exception = exception
        });
    }

    [LoggerMessage(
        EventId = 1000,
        Level = LogLevel.Error,
        Message = "Unhandled request failure. TraceId: {TraceId}")]
    private static partial void LogUnhandledRequestFailure(ILogger logger, Exception exception, string traceId);

    [LoggerMessage(
        EventId = 1001,
        Level = LogLevel.Warning,
        Message = "Handled request failure. TraceId: {TraceId}")]
    private static partial void LogHandledRequestFailure(ILogger logger, Exception exception, string traceId);
}
