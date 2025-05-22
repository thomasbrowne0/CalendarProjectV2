using System;

namespace Application.Interfaces
{
    public interface IUserSessionService
    {
        string CreateSession(Guid userId);
        bool TryGetUserId(string sessionId, out Guid userId);
        bool ValidateSession(string sessionId);
        void RemoveSession(string sessionId);
    }
}
