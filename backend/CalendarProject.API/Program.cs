using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using CalendarProject.Infrastructure.Data;

namespace CalendarProject.API
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
                try
                {
                    var context = services.GetRequiredService<AppDbContext>();
                    
                    // Apply migrations if any are pending
                    context.Database.Migrate();
                    
                    // Seed initial data
                    DbInitializer.SeedAsync(context).Wait();
                    
                    var logger = services.GetRequiredService<ILogger<Program>>();
                    logger.LogInformation("Database initialization and seeding completed successfully");
                }
                catch (Exception ex)
                {
                    var logger = services.GetRequiredService<ILogger<Program>>();
                    logger.LogError(ex, "An error occurred while initializing the database");
                }
            }
            
            // Configure the HTTP request pipeline
            startup.Configure(app, app.Environment);
            
            app.Run();
        }
    }
}
