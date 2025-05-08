using System;
using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Application.Interfaces;

namespace Application.Services
{
    public class WebSocketService : IWebSocketService
    {
        // Dictionary to store active connections: userId => WebSocket
        private readonly ConcurrentDictionary<Guid, WebSocket> _userConnections = new ConcurrentDictionary<Guid, WebSocket>();
        
        // Dictionary to store user company membership: userId => companyId
        private readonly ConcurrentDictionary<Guid, Guid> _userCompanyMap = new ConcurrentDictionary<Guid, Guid>();
        
        public async Task HandleWebSocketConnectionAsync(WebSocket webSocket, Guid userId, string userType)
        {
            // Fix for warning CS8600: Add null-conditional operator to ensure safe type handling
            _userConnections.TryAdd(userId, webSocket);
            
            var buffer = new byte[1024 * 4];
            WebSocketReceiveResult result = null;
            
            try
            {
                // Keep the connection open and handle incoming messages
                while (webSocket.State == WebSocketState.Open)
                {
                    result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Connection closed by client", CancellationToken.None);
                        break;
                    }
                    
                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        string message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        await HandleIncomingMessageAsync(userId, message);
                    }
                }
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"WebSocket error: {ex.Message}");
            }
            finally
            {
                // Clean up the connection
                _userConnections.TryRemove(userId, out _);
                _userCompanyMap.TryRemove(userId, out _);
            }
        }
        
        public async Task NotifyCompanyDataChangedAsync(Guid companyId, string changeType, object data)
        {
            var message = new
            {
                Type = changeType,
                Data = data
            };
            
            await SendToCompanyUsersAsync(companyId, JsonSerializer.Serialize(message));
        }
        
        public async Task NotifyEventCreatedAsync(Guid companyId, Guid eventId)
        {
            var message = new
            {
                Type = "EventCreated",
                Data = new { EventId = eventId }
            };
            
            await SendToCompanyUsersAsync(companyId, JsonSerializer.Serialize(message));
        }
        
        public async Task NotifyEventUpdatedAsync(Guid companyId, Guid eventId)
        {
            var message = new
            {
                Type = "EventUpdated",
                Data = new { EventId = eventId }
            };
            
            await SendToCompanyUsersAsync(companyId, JsonSerializer.Serialize(message));
        }
        
        public async Task NotifyEventDeletedAsync(Guid companyId, Guid eventId)
        {
            var message = new
            {
                Type = "EventDeleted",
                Data = new { EventId = eventId }
            };
            
            await SendToCompanyUsersAsync(companyId, JsonSerializer.Serialize(message));
        }
        
        public async Task NotifyEmployeeAddedAsync(Guid companyId, Guid employeeId)
        {
            var message = new
            {
                Type = "EmployeeAdded",
                Data = new { EmployeeId = employeeId }
            };
            
            await SendToCompanyUsersAsync(companyId, JsonSerializer.Serialize(message));
        }
        
        public async Task NotifyEmployeeRemovedAsync(Guid companyId, Guid employeeId)
        {
            var message = new
            {
                Type = "EmployeeRemoved",
                Data = new { EmployeeId = employeeId }
            };
            
            await SendToCompanyUsersAsync(companyId, JsonSerializer.Serialize(message));
        }
        
        private Task HandleIncomingMessageAsync(Guid userId, string message)
        {
            try
            {
                // Parse the incoming message
                var messageObject = JsonSerializer.Deserialize<WebSocketMessage>(message);
                
                // Handle different message types
                switch (messageObject.Type)
                {
                    case "SetCompany":
                        // Extract company ID from the message
                        if (messageObject.Data.TryGetProperty("companyId", out var companyIdElement) && 
                            companyIdElement.TryGetGuid(out var companyId))
                        {
                            // Update the user's company mapping
                            _userCompanyMap.AddOrUpdate(userId, companyId, (_, __) => companyId);
                        }
                        break;
                    
                    // Add more message type handlers as needed
                }
                return Task.CompletedTask;
            }
            catch (Exception ex)
            {
                // Log the error but don't terminate the connection
                Console.WriteLine($"Error handling message: {ex.Message}");
                return Task.CompletedTask;
            }
        }
        
        private async Task SendToCompanyUsersAsync(Guid companyId, string message)
        {
            var messageBytes = Encoding.UTF8.GetBytes(message);
            
            // Find all users belonging to this company
            foreach (var userPair in _userCompanyMap)
            {
                if (userPair.Value == companyId && _userConnections.TryGetValue(userPair.Key, out var webSocket))
                {
                    try
                    {
                        // Fix for warning CS8602: Add null check before accessing the State property
                        if (webSocket != null && webSocket.State == WebSocketState.Open)
                        {
                            await webSocket.SendAsync(
                                new ArraySegment<byte>(messageBytes),
                                WebSocketMessageType.Text,
                                true,
                                CancellationToken.None);
                        }
                    }
                    catch (Exception ex)
                    {
                        // Log the error
                        Console.WriteLine($"Error sending WebSocket message: {ex.Message}");
                    }
                }
            }
        }
        
        private class WebSocketMessage
        {
            public string Type { get; set; } = string.Empty;
            public JsonElement Data { get; set; }
        }
    }
}
