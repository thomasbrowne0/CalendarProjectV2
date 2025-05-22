using System;
using System.Collections.Concurrent;
using Application.Interfaces;

namespace Infrastructure.Services
{
    public class UserSessionService : IUserSessionService
    {
        // Simple in-memory store for sessions
        private readonly ConcurrentDictionary<string, Guid> _sessions = new();

        public string CreateSession(Guid userId)
        {
            // Generate a unique session ID
            string sessionId = Guid.NewGuid().ToString();
            _sessions[sessionId] = userId;
            return sessionId;
        }

        public bool TryGetUserId(string sessionId, out Guid userId)
        {
            return _sessions.TryGetValue(sessionId, out userId);
        }

        public bool ValidateSession(string sessionId)
        {
            return _sessions.ContainsKey(sessionId);
        }

        public void RemoveSession(string sessionId)
        {
            _sessions.TryRemove(sessionId, out _);
        }
    }
}
