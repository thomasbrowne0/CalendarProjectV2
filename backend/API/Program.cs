using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Infrastructure.Data;
using API.Proxy;
using Google.Cloud.SecretManager.V1;

namespace API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            string projectId = "calendarbackenddeploy";

            try
            {
                // Add user secrets
                builder.Configuration.AddUserSecrets<Program>();

                Console.WriteLine("Loading secrets from Google Cloud Secret Manager...");
                
                // Load connection string from Secret Manager
                string connectionString = GetSecret(projectId, "AppDb");
                if (!string.IsNullOrEmpty(connectionString))
                {
                    builder.Configuration["ConnectionStrings:DefaultConnection"] = connectionString;
                    Console.WriteLine("Successfully loaded database connection string from Secret Manager");
                }
                else
                {
                    Console.WriteLine("Warning: Failed to load database connection string from Secret Manager, using appsettings.json");
                }

                // Add services to the container
                var startup = new Startup(builder.Configuration);
                startup.ConfigureServices(builder.Services);
                
                var app = builder.Build();
                
                // Configure the HTTP request pipeline FIRST
                startup.Configure(app, app.Environment);

                // Start the proxy server (non-blocking)
                try
                {
                    var proxyConfig = new ProxyConfig();
                    proxyConfig.StartProxyServer(8081, 5000, 8181);
                    Console.WriteLine("Proxy server started successfully");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Warning: Failed to start proxy server: {ex.Message}");
                    // Don't throw - continue without proxy
                }

                // Initialize database in background (non-blocking)
                _ = Task.Run(async () =>
                {
                    try
                    {
                        using var scope = app.Services.CreateScope();
                        var services = scope.ServiceProvider;
                        var context = services.GetRequiredService<AppDbContext>();
                        var logger = services.GetRequiredService<ILogger<Program>>();
                        
                        Console.WriteLine("Starting database initialization...");
                        
                        // Apply migrations if any are pending
                        await context.Database.MigrateAsync();
                        
                        // Seed initial data
                        await DbInitializer.SeedAsync(context);
                        
                        logger.LogInformation("Database initialization and seeding completed successfully");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Database initialization failed: {ex.Message}");
                        // Log but don't crash the app
                    }
                });
                
                Console.WriteLine("Starting web application...");
                app.Run();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Application failed to start: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                
                // Try to start a minimal app that just responds to health checks
                try
                {
                    var minimalApp = builder.Build();
                    minimalApp.MapGet("/", () => "Service is starting...");
                    minimalApp.Run();
                }
                catch
                {
                    Environment.Exit(1);
                }
            }
        }

        public static string GetSecret(string projectId, string secretName)
        {
            try
            {
                var client = SecretManagerServiceClient.Create();
                var secretVersionName = new SecretVersionName(projectId, secretName, "latest");
                var secretVersion = client.AccessSecretVersion(secretVersionName);
                Console.WriteLine($"Successfully retrieved secret: {secretName}");
                return secretVersion.Payload.Data.ToStringUtf8();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error accessing secret '{secretName}': {ex.Message}");
                return string.Empty;
            }
        }
    }
}
