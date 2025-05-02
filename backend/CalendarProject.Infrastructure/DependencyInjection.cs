using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using CalendarProject.Domain.Repositories;
using CalendarProject.Domain.Services;
using CalendarProject.Application.Interfaces;
using CalendarProject.Application.Services;
using CalendarProject.Infrastructure.Data;
using CalendarProject.Infrastructure.Repositories;
using CalendarProject.Infrastructure.WebSockets;

namespace CalendarProject.Infrastructure
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
