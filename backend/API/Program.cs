using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Infrastructure.Data;
using Google.Cloud.SecretManager.V1;
using Google.Api.Gax.ResourceNames;
using API.Proxy;

namespace API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Console.WriteLine("Application starting...");
            
            var builder = WebApplication.CreateBuilder(args);
            Console.WriteLine("WebApplication builder created");
            
            // Add user secrets
            builder.Configuration.AddUserSecrets<Program>();
            Console.WriteLine("User secrets added to configuration");

            if (builder.Environment.IsProduction() || builder.Environment.IsStaging())
            {
                Console.WriteLine($"Environment is {builder.Environment.EnvironmentName}");
                // Get project ID from environment variable set by Google Cloud
                string projectId = Environment.GetEnvironmentVariable("GOOGLE_CLOUD_PROJECT");
                Console.WriteLine($"Project ID: {projectId}");
                
                if (!string.IsNullOrEmpty(projectId))
                {
                    // Replace AddGoogleCloudSecretManager with manual secret loading
                    try
                    {
                        Console.WriteLine("Attempting to load secrets from Secret Manager");
                        var secretClient = SecretManagerServiceClient.Create();
                        
                        // Load connection string
                        var connectionStringSecret = secretClient.AccessSecretVersion(
                            new SecretVersionName(projectId, "ConnectionStrings_DefaultConnection", "latest"));
                        builder.Configuration["ConnectionStrings:DefaultConnection"] = 
                            connectionStringSecret.Payload.Data.ToStringUtf8();
                            
                        // Load other secrets as needed
                        // Example: JWT Key
                        var jwtKeySecret = secretClient.AccessSecretVersion(
                            new SecretVersionName(projectId, "Jwt_Key", "latest"));
                        builder.Configuration["Jwt:Key"] = jwtKeySecret.Payload.Data.ToStringUtf8();
                        
                        Console.WriteLine("Loaded configuration from Google Cloud Secret Manager");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to load secrets from Google Cloud: {ex.Message}");
                        Console.WriteLine($"Stack trace: {ex.StackTrace}");
                    }
                }
            }
            
            Console.WriteLine("Configuring services...");
            // Add services to the container
            var startup = new Startup(builder.Configuration);
            startup.ConfigureServices(builder.Services);
            
            builder.Services.AddSingleton<IProxyConfig, ProxyConfig>();

            // Configure Kestrel BEFORE building the app
            Console.WriteLine("Configuring Kestrel...");
            builder.WebHost.ConfigureKestrel(options =>
            {
                // Listen on the internal port for HTTP
                options.ListenAnyIP(5000);
            });
            
            Console.WriteLine("Building application...");
            var app = builder.Build();
            
            // Start proxy AFTER building the app
            var proxyConfig = app.Services.GetRequiredService<IProxyConfig>();
            int publicPort = int.Parse(Environment.GetEnvironmentVariable("PORT") ?? "8080");
            proxyConfig.StartProxyServer(publicPort, 5000, 8181);
            
            Console.WriteLine("Initializing database...");
            // Initialize the database and seed data
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                try
                {
                    Console.WriteLine("Getting DbContext...");
                    var context = services.GetRequiredService<AppDbContext>();
            
                    Console.WriteLine("Checking database connection...");
                    // Check connection before attempting migrations
                    if (context.Database.CanConnect())
                    {
                        Console.WriteLine("Database connection successful");
                        // Apply migrations if any are pending
                        Console.WriteLine("Applying migrations...");
                        context.Database.Migrate();
                
                        // Seed initial data
                        Console.WriteLine("Seeding data...");
                        DbInitializer.SeedAsync(context).Wait();
                
                        var logger = services.GetRequiredService<ILogger<Program>>();
                        logger.LogInformation("Database initialization and seeding completed successfully");
                    }
                    else
                    {
                        Console.WriteLine("Cannot connect to database");
                        var logger = services.GetRequiredService<ILogger<Program>>();
                        logger.LogWarning("Could not connect to database. Skipping migrations and seeding.");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Database initialization error: {ex.Message}");
                    Console.WriteLine($"Stack trace: {ex.StackTrace}");
                    var logger = services.GetRequiredService<ILogger<Program>>();
                    logger.LogError(ex, "An error occurred while initializing the database");
                    // Don't rethrow - let the application continue starting
                }
            }
            
            Console.WriteLine("Configuring HTTP request pipeline...");
            // Configure the HTTP request pipeline
            startup.Configure(app, app.Environment);
            
            Console.WriteLine("Adding diagnostic endpoints...");
            app.MapGet("/health", () => {
                Console.WriteLine("Health check endpoint called");
                return Results.Ok("Healthy");
            });
            
            app.MapGet("/dbcheck", async (AppDbContext db) => {
                Console.WriteLine("Database check endpoint called");
                try {
                    var canConnect = await db.Database.CanConnectAsync();
                    Console.WriteLine($"Database connection check result: {canConnect}");
                    return Results.Ok(new { Connected = canConnect });
                }
                catch (Exception ex) {
                    Console.WriteLine($"Database connection error: {ex.Message}");
                    return Results.BadRequest(new { Error = ex.Message, StackTrace = ex.StackTrace });
                }
            });
            
            Console.WriteLine("Starting application server...");
            app.Run();
            Console.WriteLine("Application stopped");
        }
    }
}