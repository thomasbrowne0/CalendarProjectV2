using System;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Infrastructure.WebSockets
{
    public class WebSocketService : IWebSocketService
    {
        private readonly WebSocketConnectionManager _connectionManager;
        private readonly ILogger<WebSocketService> _logger;

        public WebSocketService(ILogger<WebSocketService> logger)
        {
            _connectionManager = new WebSocketConnectionManager();
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public async Task HandleWebSocketConnectionAsync(WebSocket webSocket, Guid userId, string userType)
        {
            _logger.LogInformation($"Handling WebSocket connection for user: {userId}, type: {userType}");
            _connectionManager.AddConnection(webSocket, userId, userType);
            
            var buffer = new byte[1024 * 4];
            WebSocketReceiveResult result = null;
            
            try
            {
                while (webSocket.State == WebSocketState.Open)
                {
                    result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        _logger.LogInformation($"WebSocket close request received for user {userId}");
                        await _connectionManager.RemoveConnection(userId);
                        break;
                    }
                    
                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        _logger.LogDebug($"WebSocket message received from user {userId}: {message}");
                        await HandleIncomingMessageAsync(userId, message);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error in WebSocket connection for user {userId}");
            }
            finally
            {
                _logger.LogInformation($"Closing WebSocket connection for user {userId}");
                await _connectionManager.RemoveConnection(userId);
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
        
        private async Task HandleIncomingMessageAsync(Guid userId, string message)
        {
            try
            {
                _logger.LogDebug($"Processing message from user {userId}: {message}");
                var messageObj = JsonDocument.Parse(message);
                var root = messageObj.RootElement;
                
                if (root.TryGetProperty("type", out var typeElement))
                {
                    var messageType = typeElement.GetString();
                    _logger.LogDebug($"Message type: {messageType}");
                    
                    if (messageType == "SetCompany" && 
                        root.TryGetProperty("data", out var dataElement) &&
                        dataElement.TryGetProperty("companyId", out var companyIdElement))
                    {
                        if (Guid.TryParse(companyIdElement.GetString() ?? companyIdElement.ToString(), out var companyId))
                        {
                            _logger.LogInformation($"User {userId} setting company to {companyId}");
                            _connectionManager.UpdateCompanyForConnection(userId, companyId);
                        }
                        else
                        {
                            _logger.LogWarning($"Invalid company ID format in message from user {userId}");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error handling WebSocket message from user {userId}");
            }
        }
        
        private async Task SendToCompanyUsersAsync(Guid companyId, string message)
        {
            var connections = _connectionManager.GetConnectionsByCompany(companyId);
            var messageBytes = Encoding.UTF8.GetBytes(message);
            
            foreach (var connection in connections)
            {
                if (connection.Socket.State == WebSocketState.Open)
                {
                    try
                    {
                        await connection.Socket.SendAsync(
                            new ArraySegment<byte>(messageBytes),
                            WebSocketMessageType.Text,
                            true,
                            CancellationToken.None);
                    }
                    catch (Exception)
                    {
                        // Failed to send message, connection might be closed
                        await _connectionManager.RemoveConnection(connection.Id);
                    }
                }
            }
        }
    }
}
