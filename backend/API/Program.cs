using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Infrastructure.Data;

namespace API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            
            // Add user secrets
            builder.Configuration.AddUserSecrets<Program>();
            
            // Add services to the container
            var startup = new Startup(builder.Configuration);
            startup.ConfigureServices(builder.Services);
            
            var app = builder.Build();
            
            // Initialize the database and seed data
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var logger = services.GetRequiredService<ILogger<Program>>(); // Define logger once at the beginning
                
                try
                {
                    var context = services.GetRequiredService<AppDbContext>();
                    
                    // Check for pending migrations instead of applying directly
                    var pendingMigrations = context.Database.GetPendingMigrations();
                    if (pendingMigrations.Any())
                    {
                        try
                        {
                            context.Database.Migrate();
                        }
                        catch (Exception ex)
                        {
                            // Just log the error but continue - the database might already be set up
                            logger.LogWarning(ex, "Error applying migrations - the database might already be initialized");
                        }
                    }
                    
                    // Seed initial data
                    DbInitializer.SeedAsync(context).Wait();
                    logger.LogInformation("Database initialization and seeding completed successfully");
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "An error occurred while initializing the database");
                }
            }
            
            // Configure the HTTP request pipeline
            startup.Configure(app, app.Environment);

            app.Use(async (context, next) =>
            {
                // Log request details
                var requestBody = "";
                if (context.Request.Path.ToString().Contains("/api/auth/login"))
                {
                    context.Request.EnableBuffering();
                    using (var reader = new System.IO.StreamReader(
                        context.Request.Body, encoding: System.Text.Encoding.UTF8, detectEncodingFromByteOrderMarks: false, 
                        bufferSize: -1, leaveOpen: true))
                    {
                        requestBody = await reader.ReadToEndAsync();
                        // Reset the position to 0 so it can be read again
                        context.Request.Body.Position = 0;
                    }
                    Console.WriteLine($"Login request: {requestBody}");
                }

                // Log response details
                var originalBodyStream = context.Response.Body;
                using (var responseBody = new System.IO.MemoryStream())
                {
                    context.Response.Body = responseBody;

                    try
                    {
                        await next();
                    }
                    finally
                    {
                        if (context.Request.Path.ToString().Contains("/api/auth/login"))
                        {
                            responseBody.Seek(0, System.IO.SeekOrigin.Begin);
                            var text = await new System.IO.StreamReader(responseBody).ReadToEndAsync();
                            Console.WriteLine($"Login response: {text}");
                            responseBody.Seek(0, System.IO.SeekOrigin.Begin);
                            await responseBody.CopyToAsync(originalBodyStream);
                        }
                        else
                        {
                            responseBody.Seek(0, System.IO.SeekOrigin.Begin);
                            await responseBody.CopyToAsync(originalBodyStream);
                        }
                    }
                }
            });
            
            app.Run();
        }
    }
}
