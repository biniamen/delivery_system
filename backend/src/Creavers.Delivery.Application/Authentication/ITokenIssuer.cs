using Creavers.Delivery.Domain.Entities;

namespace Creavers.Delivery.Application.Authentication;

public interface ITokenIssuer
{
    LoginResponse Issue(User user);
}

