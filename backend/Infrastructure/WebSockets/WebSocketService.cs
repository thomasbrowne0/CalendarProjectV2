using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Application.Interfaces;
using Fleck;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Security.Cryptography.X509Certificates;

namespace Infrastructure.WebSockets
{
    public class WebSocketService : IWebSocketService, IDisposable
    {
        private readonly WebSocketConnectionManager _connectionManager;
        private readonly ILogger<WebSocketService> _logger;
        private readonly WebSocketOptions _options;
        private readonly WebSocketServer _server;
        private readonly IServiceProvider _serviceProvider;
        private bool _disposed = false;

        public WebSocketService(
            ILogger<WebSocketService> logger,
            IOptions<WebSocketOptions> options,
            IServiceProvider serviceProvider,
            ILoggerFactory loggerFactory)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _options = options?.Value ?? throw new ArgumentNullException(nameof(options));
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
            // Create proper logger for the connection manager
            _connectionManager = new WebSocketConnectionManager(
                loggerFactory.CreateLogger<WebSocketConnectionManager>());

            // Configure and start the WebSocket server
            var scheme = _options.SecureConnection ? "wss" : "ws";
            var serverUrl = $"{scheme}://{_options.Host}:{_options.Port}";
            _logger.LogInformation($"Starting WebSocket server at {serverUrl}");

            _server = new WebSocketServer(serverUrl);
            
            if (_options.SecureConnection && !string.IsNullOrEmpty(_options.CertificatePath))
            {
                // Use X509Certificate2 with modern approach
                var loader = new X509Certificate2Collection();
                var certificate = new X509Certificate2(_options.CertificatePath, _options.CertificatePassword);
                loader.Add(certificate);
                _server.Certificate = loader[0];
                _logger.LogInformation("WebSocket server configured with SSL");
            }

            // Start the server
            _server.Start(socket =>
            {
                // Set up event handlers
                socket.OnOpen = () => OnSocketOpened(socket);
                socket.OnClose = () => OnSocketClosed(socket);
                socket.OnMessage = message => OnMessageReceived(socket, message);
                socket.OnError = error => OnSocketError(socket, error);
            });

            _logger.LogInformation("WebSocket server started successfully");
        }

        // IWebSocketService implementation - handle a new connection
        public Task HandleWebSocketConnectionAsync(System.Net.WebSockets.WebSocket webSocket, Guid userId, string userType)
        {
            // This method is kept for interface compatibility but is not used with Fleck
            // Fleck manages connections differently through its event-based system
            _logger.LogWarning("HandleWebSocketConnectionAsync called but is not implemented with Fleck");
            return Task.CompletedTask;
        }

        // Event handlers
        private void OnSocketOpened(IWebSocketConnection socket)
        {
            _logger.LogInformation($"WebSocket connection opened: {socket.ConnectionInfo.Id}");
            // The actual user authentication and connection registration happens when the client sends
            // an authentication message with their token
        }

        private void OnSocketClosed(IWebSocketConnection socket)
        {
            _logger.LogInformation($"WebSocket connection closed: {socket.ConnectionInfo.Id}");
            
            // Find and remove the user connection
            var connection = _connectionManager._connections.FirstOrDefault(c => 
                c.Value.Socket.ConnectionInfo.Id == socket.ConnectionInfo.Id);
                
            if (connection.Key != Guid.Empty)
            {
                _connectionManager.RemoveConnection(connection.Key);
            }
        }

        private void OnSocketError(IWebSocketConnection socket, Exception error)
        {
            _logger.LogError(error, $"WebSocket error on connection {socket.ConnectionInfo.Id}");
        }

        private void OnMessageReceived(IWebSocketConnection socket, string message)
        {
            _logger.LogDebug($"Message received from {socket.ConnectionInfo.Id}: {message}");
            
            try
            {
                var messageObj = JsonDocument.Parse(message);
                var root = messageObj.RootElement;
                
                if (root.TryGetProperty("type", out var typeElement))
                {
                    var messageType = typeElement.GetString()?.ToLower();
                    
                    switch (messageType)
                    {
                        case "authenticate":
                            HandleAuthenticationMessage(socket, root);
                            break;
                        case "setcompany":
                            HandleSetCompanyMessage(socket, root);
                            break;
                        default:
                            _logger.LogWarning($"Unknown message type: {messageType}");
                            break;
                    }
                }
                else
                {
                    _logger.LogWarning("Message received without a type property");
                }
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "Error parsing WebSocket message as JSON");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing WebSocket message");
            }
        }

        private void HandleAuthenticationMessage(IWebSocketConnection socket, JsonElement messageRoot)
        {
            if (messageRoot.TryGetProperty("token", out var tokenElement))
            {
                var token = tokenElement.GetString();
                if (!string.IsNullOrEmpty(token))
                {
                    var userInfo = ExtractUserInfoFromToken(token);
                    if (userInfo.userId != Guid.Empty)
                    {
                        // Register the connection
                        _connectionManager.AddConnection(socket, userInfo.userId, userInfo.userType);
                        
                        // Confirm authentication to the client
                        var response = new
                        {
                            Type = "AuthenticationResult",
                            Success = true,
                            UserId = userInfo.userId
                        };
                        
                        socket.Send(JsonSerializer.Serialize(response));
                        _logger.LogInformation($"User {userInfo.userId} authenticated successfully");
                    }
                    else
                    {
                        SendAuthenticationFailure(socket, "Invalid token");
                    }
                }
                else
                {
                    SendAuthenticationFailure(socket, "Token is empty");
                }
            }
            else
            {
                SendAuthenticationFailure(socket, "No token provided");
            }
        }
        
        private void SendAuthenticationFailure(IWebSocketConnection socket, string reason)
        {
            var response = new
            {
                Type = "AuthenticationResult",
                Success = false,
                Reason = reason
            };
            
            socket.Send(JsonSerializer.Serialize(response));
            _logger.LogWarning($"Authentication failed: {reason}");
        }

        private void HandleSetCompanyMessage(IWebSocketConnection socket, JsonElement messageRoot)
        {
            // Find the user ID for this socket
            var connection = _connectionManager._connections.FirstOrDefault(c => 
                c.Value.Socket.ConnectionInfo.Id == socket.ConnectionInfo.Id);
                
            if (connection.Key == Guid.Empty)
            {
                _logger.LogWarning("SetCompany message received from unauthenticated connection");
                return;
            }
            
            if (messageRoot.TryGetProperty("data", out var dataElement) &&
                dataElement.TryGetProperty("companyId", out var companyIdElement))
            {
                if (Guid.TryParse(companyIdElement.GetString() ?? companyIdElement.ToString(), out var companyId))
                {
                    _logger.LogInformation($"User {connection.Key} setting company to {companyId}");
                    _connectionManager.UpdateCompanyForConnection(connection.Key, companyId);
                    
                    // Confirm company set
                    var response = new
                    {
                        Type = "CompanySet",
                        CompanyId = companyId
                    };
                    socket.Send(JsonSerializer.Serialize(response));
                }
                else
                {
                    _logger.LogWarning($"Invalid company ID format in SetCompany message");
                }
            }
        }

        private (Guid userId, string userType) ExtractUserInfoFromToken(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                _logger.LogDebug("Attempting to read token in WebSocketService");

                if (tokenHandler.CanReadToken(token))
                {
                    var jwtToken = tokenHandler.ReadJwtToken(token);
                    
                    // Extract user ID
                    var userIdClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == "nameid");
                    if (userIdClaim != null && Guid.TryParse(userIdClaim.Value, out Guid userId))
                    {
                        // Extract user type
                        var userTypeClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == "UserType");
                        string userType = userTypeClaim?.Value ?? "Unknown";
                        
                        return (userId, userType);
                    }
                }
                
                _logger.LogWarning("Failed to extract user information from token");
                return (Guid.Empty, string.Empty);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception during ExtractUserInfoFromToken");
                return (Guid.Empty, string.Empty);
            }
        }

        

        // Notification methods
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
        
        private Task SendToCompanyUsersAsync(Guid companyId, string message)
        {
            var connections = _connectionManager.GetConnectionsByCompany(companyId);
            
            foreach (var connection in connections)
            {
                try
                {
                    connection.Socket.Send(message);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error sending message to user {connection.Id}");
                    // Connection might be broken, remove it
                    _connectionManager.RemoveConnection(connection.Id);
                }
            }
            
            return Task.CompletedTask;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    // Dispose managed resources
                    _server?.Dispose();
                }

                _disposed = true;
            }
        }

        ~WebSocketService()
        {
            Dispose(false);
        }
    }
}