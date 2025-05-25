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
using System.Net.WebSockets;

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
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));            _connectionManager = new WebSocketConnectionManager(
                loggerFactory.CreateLogger<WebSocketConnectionManager>());

            /* We need to configure the WebSocket server with proper URL binding
               to handle real-time communication for calendar updates */
            var serverUrl = $"ws://{_options.Host}:{_options.Port}";
            _logger.LogInformation($"Starting WebSocket server at {serverUrl}");

            _server = new WebSocketServer(serverUrl);

            _server.Start(socket =>
            {
                socket.OnOpen = () => OnSocketOpened(socket);
                socket.OnClose = () => OnSocketClosed(socket);
                socket.OnMessage = message => OnMessageReceived(socket, message);
                socket.OnError = error => OnSocketError(socket, error);
            });

            _logger.LogInformation("WebSocket server started successfully");
        }

        public Task HandleWebSocketConnectionAsync(System.Net.WebSockets.WebSocket webSocket, Guid userId, string userType)
        {
            /* We need to keep this method for interface compatibility but Fleck
               manages connections through its event-based system instead */
            _logger.LogWarning("HandleWebSocketConnectionAsync called but is not implemented with Fleck");
            return Task.CompletedTask;
        }

        private void OnSocketOpened(IWebSocketConnection socket)
        {
            _logger.LogInformation($"WebSocket connection opened: {socket.ConnectionInfo.Id}");
            /* We need to wait for client authentication message because connections
               are not authenticated until the client sends their JWT token */
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

        public async Task ProxyToFleckAsync(System.Net.WebSockets.WebSocket webSocket, string fleckUrl)
        {
            _logger.LogInformation($"Proxying WebSocket connection to Fleck server at {fleckUrl}");

            using var clientWebSocket = new ClientWebSocket();
            var cancellationTokenSource = new CancellationTokenSource();

            try
            {
                // Connect to the Fleck WebSocket server
                await clientWebSocket.ConnectAsync(new Uri(fleckUrl), cancellationTokenSource.Token);

                var buffer = new byte[8192];

                // Task to receive messages from Fleck and send them to the client
                var receiveTask = Task.Run(async () =>
                {
                    try
                    {
                        while (clientWebSocket.State == WebSocketState.Open)
                        {
                            var result = await clientWebSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cancellationTokenSource.Token);
                            if (result.MessageType == WebSocketMessageType.Close)
                            {
                                _logger.LogInformation("Fleck WebSocket closed the connection.");
                                await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by Fleck", CancellationToken.None);
                                break;
                            }

                            await webSocket.SendAsync(new ArraySegment<byte>(buffer, 0, result.Count), result.MessageType, result.EndOfMessage, CancellationToken.None);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error receiving data from Fleck WebSocket.");
                        cancellationTokenSource.Cancel();
                    }
                });

                // Task to receive messages from the client and send them to Fleck
                var sendTask = Task.Run(async () =>
                {
                    try
                    {
                        while (webSocket.State == WebSocketState.Open)
                        {
                            var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cancellationTokenSource.Token);
                            if (result.MessageType == WebSocketMessageType.Close)
                            {
                                _logger.LogInformation("Client WebSocket closed the connection.");
                                await clientWebSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by client", CancellationToken.None);
                                break;
                            }

                            await clientWebSocket.SendAsync(new ArraySegment<byte>(buffer, 0, result.Count), result.MessageType, result.EndOfMessage, CancellationToken.None);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error receiving data from client WebSocket.");
                        cancellationTokenSource.Cancel();
                    }
                });

                // Wait for either task to complete
                await Task.WhenAny(receiveTask, sendTask);
            }
            catch (System.Net.WebSockets.WebSocketException ex)
            {
                _logger.LogError(ex, "WebSocket exception occurred while proxying.");
                await webSocket.CloseAsync(WebSocketCloseStatus.InternalServerError, "WebSocket error", CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error occurred while proxying WebSocket connection.");
                await webSocket.CloseAsync(WebSocketCloseStatus.InternalServerError, "Unexpected error", CancellationToken.None);
            }
            finally
            {
                // Ensure both WebSocket connections are closed
                if (webSocket.State == WebSocketState.Open || webSocket.State == WebSocketState.CloseReceived)
                {
                    await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Proxy closed", CancellationToken.None);
                }

                if (clientWebSocket.State == WebSocketState.Open || clientWebSocket.State == WebSocketState.CloseReceived)
                {
                    await clientWebSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Proxy closed", CancellationToken.None);
                }

                cancellationTokenSource.Cancel();
                _logger.LogInformation("WebSocket proxying completed.");
            }
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