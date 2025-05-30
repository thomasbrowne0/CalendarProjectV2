using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Extensions.Logging;
using Fleck;

namespace Infrastructure.WebSockets;

public class WebSocketConnectionManager
{
    /* We need internal access for WebSocketService to directly manage
       connections because Fleck handles connection lifecycle differently */
    internal readonly ConcurrentDictionary<Guid, FleckConnection> _connections = new();
    private readonly ILogger<WebSocketConnectionManager> _logger;

    public WebSocketConnectionManager(ILogger<WebSocketConnectionManager> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public FleckConnection? GetConnectionById(Guid id)
    {
        _connections.TryGetValue(id, out var connection);
        return connection;
    }

    public IEnumerable<FleckConnection> GetConnectionsByCompany(Guid companyId)
    {
        return _connections.Values
            .Where(c => c.CompanyId == companyId)
            .ToList();
    }

    public void AddConnection(IWebSocketConnection socket, Guid userId, string userType, Guid? companyId = null)
    {
        var connection = new FleckConnection
        {
            Id = userId,
            Socket = socket,
            UserType = userType ?? "Unknown",
            CompanyId = companyId
        };

        _connections.AddOrUpdate(userId, connection, (_, _) => connection);
        _logger.LogInformation($"Added WebSocket connection for user {userId} of type {userType}");
    }

    public void UpdateCompanyForConnection(Guid userId, Guid companyId)
    {
        if (_connections.TryGetValue(userId, out var connection))
        {
            connection.CompanyId = companyId;
            _logger.LogInformation($"Updated company to {companyId} for user {userId}");
        }
    }

    public void RemoveConnection(Guid id)
    {
        if (_connections.TryRemove(id, out var connection))
            _logger.LogInformation($"Removed WebSocket connection for user {id}");
    }
}

public class FleckConnection
{
    public Guid Id { get; set; }
    public required IWebSocketConnection Socket { get; set; }
    public required string UserType { get; set; } = string.Empty;
    public Guid? CompanyId { get; set; }
}