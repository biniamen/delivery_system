using Creavers.Delivery.Domain.Entities;

namespace Creavers.Delivery.Application.Authentication;

public interface IPasswordService
{
    string Hash(User user, string password);
    bool Verify(User user, string passwordHash, string suppliedPassword);
}

