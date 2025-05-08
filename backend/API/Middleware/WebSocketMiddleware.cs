using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net.WebSockets;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Application.Interfaces;

namespace API.Middleware
{
    public class WebSocketMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IWebSocketService _webSocketService;
        private readonly ILogger<WebSocketMiddleware> _logger;
        private readonly IServiceProvider _serviceProvider;

        public WebSocketMiddleware(
            RequestDelegate next,
            IWebSocketService webSocketService,
            ILogger<WebSocketMiddleware> logger,
            IServiceProvider serviceProvider)
        {
            _next = next ?? throw new ArgumentNullException(nameof(next));
            _webSocketService = webSocketService ?? throw new ArgumentNullException(nameof(webSocketService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (context.Request.Path == "/ws")
            {
                if (context.WebSockets.IsWebSocketRequest)
                {
                    // Extract token from query string
                    var token = context.Request.Query["token"].ToString();
                    
                    // Create a scope to resolve scoped services
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var authService = scope.ServiceProvider.GetRequiredService<IAuthService>();
                        
                        if (string.IsNullOrEmpty(token) || !await authService.ValidateTokenAsync(token))
                        {
                            context.Response.StatusCode = 401; // Unauthorized
                            _logger.LogWarning("Unauthorized WebSocket connection attempt");
                            return;
                        }

                        try
                        {
                            // Extract user ID and type from token
                            var userInfo = ExtractUserInfoFromToken(token);
                            if (userInfo.userId == Guid.Empty)
                            {
                                context.Response.StatusCode = 401; // Unauthorized
                                _logger.LogWarning("Could not extract user information from token");
                                return;
                            }
                            
                            // Accept WebSocket connection
                            var webSocket = await context.WebSockets.AcceptWebSocketAsync();
                            _logger.LogInformation($"WebSocket connection established for user {userInfo.userId}");
                            
                            // Handle the WebSocket connection
                            await _webSocketService.HandleWebSocketConnectionAsync(webSocket, userInfo.userId, userInfo.userType);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error handling WebSocket connection");
                            context.Response.StatusCode = 500; // Internal Server Error
                        }
                    }
                }
                else
                {
                    _logger.LogWarning("Non-WebSocket request to WebSocket endpoint");
                    context.Response.StatusCode = 400; // Bad Request
                }
            }
            else
            {
                await _next(context);
            }
        }

        private (Guid userId, string userType) ExtractUserInfoFromToken(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                if (tokenHandler.CanReadToken(token))
                {
                    var jwtToken = tokenHandler.ReadJwtToken(token);
                    
                    // Extract user ID
                    var userIdClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier);
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
                _logger.LogError(ex, "Error parsing JWT token");
                return (Guid.Empty, string.Empty);
            }
        }
    }
}
