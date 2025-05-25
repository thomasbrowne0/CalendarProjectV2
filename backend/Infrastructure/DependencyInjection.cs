using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Domain.IRepositories;
using Domain.IServices;
using Application.Interfaces;
using Application.Services;
using Infrastructure.Data;
using Infrastructure.Repositories;
using Infrastructure.WebSockets;

namespace Infrastructure
{
    public static class DependencyInjection
    {        public static IServiceCollection AddInfrastructure(
            this IServiceCollection services, 
            IConfiguration configuration)
        {
            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(
                    configuration.GetConnectionString("DefaultConnection"),
                    b => b.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

            services.AddScoped<ICompanyRepository, CompanyRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<ICompanyOwnerRepository, CompanyOwnerRepository>();
            services.AddScoped<IEmployeeRepository, EmployeeRepository>();
            services.AddScoped<ICalendarEventRepository, CalendarEventRepository>();
            
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            
            /*
             * We need WebSocket configuration from appsettings.json because the WebSocket server
             * runs independently from the main web API and requires specific host/port settings
             */
            services.Configure<WebSocketOptions>(options => 
            {
                options.Host = configuration["WebSockets:Host"] ?? "0.0.0.0";
                options.Port = int.Parse(configuration["WebSockets:Port"] ?? "8181");
                options.SecureConnection = bool.Parse(configuration["WebSockets:SecureConnection"] ?? "false");
                options.CertificatePath = configuration["WebSockets:CertificatePath"];
                options.CertificatePassword = configuration["WebSockets:CertificatePassword"];
            });
            
            services.AddSingleton<IWebSocketService, Infrastructure.WebSockets.WebSocketService>();

            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<ICompanyAppService, CompanyAppService>();
            services.AddScoped<IEmployeeAppService, EmployeeAppService>();
            services.AddScoped<ICalendarAppService, CalendarAppService>();
            
            return services;
        }
    }
}
