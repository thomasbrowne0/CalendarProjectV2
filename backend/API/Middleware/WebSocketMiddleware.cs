using System;
using System.Net.WebSockets;
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
                            return;
                        }

                        try
                        {
                            // Extract user ID and type from token
                            (Guid userId, string userType) = ExtractUserInfoFromToken(token);
                            
                            // Accept WebSocket connection
                            var webSocket = await context.WebSockets.AcceptWebSocketAsync();
                            
                            // Handle the WebSocket connection
                            await _webSocketService.HandleWebSocketConnectionAsync(webSocket, userId, userType);
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
            // In a real implementation, you would extract this information from the JWT token
            // This is a placeholder implementation
            // You could use a JWT library to parse the token and extract claims

            // For now, we'll just return dummy values
            return (Guid.NewGuid(), "Employee");
        }
    }
}
