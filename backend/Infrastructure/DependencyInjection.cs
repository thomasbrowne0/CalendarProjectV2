using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Domain.IRepositories;
using Domain.IServices;
using Application.Interfaces;
using Application.Services;
using Infrastructure.Data;
using Infrastructure.Repositories;
using Infrastructure.WebSockets;
using Infrastructure.Services;

namespace Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(
            this IServiceCollection services, 
            IConfiguration configuration)
        {
            // First register session service with fully qualified names to avoid ambiguity
            services.AddSingleton<Application.Interfaces.IUserSessionService, Infrastructure.Services.UserSessionService>();

            // Register DbContext with PostgreSQL
            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(
                    configuration.GetConnectionString("DefaultConnection"),
                    b => b.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

            // Register repositories
            services.AddScoped<ICompanyRepository, CompanyRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<ICompanyOwnerRepository, CompanyOwnerRepository>();
            services.AddScoped<IEmployeeRepository, EmployeeRepository>();
            services.AddScoped<ICalendarEventRepository, CalendarEventRepository>();
            
            // Register UnitOfWork
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            
            // Configure WebSocket options with explicit configuration access
            var webSocketsSection = configuration.GetSection("WebSockets");
            services.Configure<WebSocketOptions>(options => 
            {
                options.Host = webSocketsSection["Host"] ?? "0.0.0.0";
                options.Port = int.Parse(webSocketsSection["Port"] ?? "8181");
                options.SecureConnection = bool.Parse(webSocketsSection["SecureConnection"] ?? "false");
                options.CertificatePath = webSocketsSection["CertificatePath"] ?? string.Empty;
                options.CertificatePassword = webSocketsSection["CertificatePassword"] ?? string.Empty;
            });
            
            // Register Application services
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<ICompanyAppService, CompanyAppService>();
            services.AddScoped<IEmployeeAppService, EmployeeAppService>();
            services.AddScoped<ICalendarAppService, CalendarAppService>();
            
            // Register WebSocket service with fully qualified names
            services.AddSingleton<Application.Interfaces.IWebSocketService, Infrastructure.WebSockets.WebSocketService>();

            return services;
        }
    }
}
