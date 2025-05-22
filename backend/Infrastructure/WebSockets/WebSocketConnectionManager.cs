using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Fleck;
using Microsoft.Extensions.Logging;

namespace Infrastructure.WebSockets
{
    public class WebSocketConnectionManager
    {
        private readonly ILogger<WebSocketConnectionManager> _logger;
        public readonly ConcurrentDictionary<Guid, UserConnection> _connections = new();

        public WebSocketConnectionManager(ILogger<WebSocketConnectionManager> logger)
        {
            _logger = logger;
        }

        public void AddConnection(IWebSocketConnection socket, Guid userId)
        {
            _logger.LogInformation($"Adding connection for user {userId}");
            _connections[userId] = new UserConnection(userId, socket);
        }

        public void UpdateCompanyForConnection(Guid userId, Guid companyId)
        {
            if (_connections.TryGetValue(userId, out var connection))
            {
                connection.CompanyId = companyId;
                _logger.LogInformation($"Updated company ID to {companyId} for user {userId}");
            }
            else
            {
                _logger.LogWarning($"Cannot update company: User {userId} not found in connections");
            }
        }

        public void RemoveConnection(Guid userId)
        {
            if (_connections.TryRemove(userId, out _))
            {
                _logger.LogInformation($"Removed connection for user {userId}");
            }
        }

        public IEnumerable<UserConnection> GetConnectionsByCompany(Guid companyId)
        {
            return _connections.Values.Where(c => c.CompanyId == companyId);
        }
    }

    public class UserConnection
    {
        public Guid Id { get; }
        public IWebSocketConnection Socket { get; }
        public Guid CompanyId { get; set; }

        public UserConnection(Guid id, IWebSocketConnection socket)
        {
            Id = id;
            Socket = socket;
            CompanyId = Guid.Empty; // Default empty company ID
        }
    }
}