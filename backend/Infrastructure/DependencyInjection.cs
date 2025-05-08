using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Domain.Repositories;
using Domain.Services;
using Application.Interfaces;
using Application.Services;
using Infrastructure.Data;
using Infrastructure.Repositories;
using Infrastructure.WebSockets;

namespace Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(
            this IServiceCollection services, 
            IConfiguration configuration)
        {
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
            
            // Fix ambiguous reference by using the fully qualified name
            services.AddSingleton<IWebSocketService, Infrastructure.WebSockets.WebSocketService>();

            // Register Application services
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<ICompanyAppService, CompanyAppService>();
            services.AddScoped<IEmployeeAppService, EmployeeAppService>();
            services.AddScoped<ICalendarAppService, CalendarAppService>();
            
            return services;
        }
    }
}
