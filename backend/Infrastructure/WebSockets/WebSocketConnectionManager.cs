using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.WebSockets;
using System.Threading;
using System.Threading.Tasks;

namespace Infrastructure.WebSockets
{
    public class WebSocketConnectionManager
    {
        private readonly ConcurrentDictionary<Guid, WebSocketConnection> _connections = 
            new ConcurrentDictionary<Guid, WebSocketConnection>();
        
        public WebSocketConnection? GetConnectionById(Guid id)
        {
            _connections.TryGetValue(id, out var connection);
            return connection;
        }

        public IEnumerable<WebSocketConnection> GetConnectionsByCompany(Guid companyId)
        {
            return _connections.Values
                .Where(c => c.CompanyId == companyId)
                .ToList(); // Create a snapshot to avoid enumeration issues
        }

        public Guid AddConnection(WebSocket socket, Guid userId, string userType, Guid? companyId = null)
        {
            var connection = new WebSocketConnection
            {
                Id = userId,
                Socket = socket,
                UserType = userType ?? "Unknown",
                CompanyId = companyId
            };

            _connections.AddOrUpdate(userId, connection, (_, _) => connection);
            return userId;
        }

        public void UpdateCompanyForConnection(Guid userId, Guid companyId)
        {
            if (_connections.TryGetValue(userId, out var connection))
            {
                connection.CompanyId = companyId;
            }
        }

        public async Task RemoveConnection(Guid id)
        {
            if (_connections.TryRemove(id, out var connection))
            {
                if (connection.Socket.State != WebSocketState.Closed &&
                    connection.Socket.State != WebSocketState.Aborted)
                {
                    try
                    {
                        await connection.Socket.CloseAsync(
                            WebSocketCloseStatus.NormalClosure,
                            "Connection closed",
                            CancellationToken.None);
                    }
                    catch (Exception)
                    {
                        // Already closed or disposed
                    }
                }
            }
        }
    }

    public class WebSocketConnection
    {
        public Guid Id { get; set; }
        public required WebSocket Socket { get; set; }
        public required string UserType { get; set; } = string.Empty;
        public Guid? CompanyId { get; set; }
    }
}
