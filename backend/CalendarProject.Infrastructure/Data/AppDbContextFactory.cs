using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace CalendarProject.Infrastructure.Data
{
    public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            // For migrations, use a direct connection string
            // Replace these credentials with your actual PostgreSQL credentials
            var connectionString = "Host=localhost;Database=CalendarProjectDb;Username=calendarapp;Password=ilovemilk";
            
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql(
                connectionString,
                b => b.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName));

            return new AppDbContext(optionsBuilder.Options);
        }
    }
}
