using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;
using System.Security.Cryptography;
using System.Text;

namespace Infrastructure.Data
{
    public static class DbInitializer
    {
        private static string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }

        public static async Task SeedAsync(AppDbContext context)
        {
            // Ensure database is created
            await context.Database.EnsureCreatedAsync();

            // Only seed if no users exist
            if (await context.Users.AnyAsync())
            {
                return; // Database already has data
            }

            // Create company owners
            var owner1 = new CompanyOwner(
                "John", 
                "Smith", 
                "owner@example.com", 
                HashPassword("Password123")); // Hash the password

            var owner2 = new CompanyOwner(
                "Sarah", 
                "Johnson", 
                "sarah@example.com", 
                HashPassword("Password123")); // Hash the password

            await context.CompanyOwners.AddRangeAsync(owner1, owner2);
            await context.SaveChangesAsync();

            // Create companies
            var company1 = new Company("Acme Corp", "123456789", owner1.Id);
            var company2 = new Company("Tech Solutions", "987654321", owner2.Id);
            
            await context.Companies.AddRangeAsync(company1, company2);
            await context.SaveChangesAsync();

            // Create employees for Acme Corp
            var employees1 = new List<Employee>
            {
                new Employee("Michael", "Brown", "michael@acme.com", HashPassword("Password123"), company1.Id, "Developer"),
                new Employee("Emma", "Davis", "emma@acme.com", HashPassword("Password123"), company1.Id, "Designer"),
                new Employee("David", "Wilson", "david@acme.com", HashPassword("Password123"), company1.Id, "Project Manager")
            };

            // Create employees for Tech Solutions
            var employees2 = new List<Employee>
            {
                new Employee("Robert", "Jones", "robert@techsolutions.com", HashPassword("Password123"), company2.Id, "Engineer"),
                new Employee("Jennifer", "Garcia", "jennifer@techsolutions.com", HashPassword("Password123"), company2.Id, "QA Analyst")
            };

            await context.Employees.AddRangeAsync(employees1);
            await context.Employees.AddRangeAsync(employees2);
            await context.SaveChangesAsync();

            // Create calendar events
            var now = DateTime.UtcNow; // Change from DateTime.Now to DateTime.UtcNow
            
            var events1 = new List<CalendarEvent>
            {
                new CalendarEvent(
                    "Team Meeting", 
                    "Weekly team sync", 
                    now.AddDays(1).Date.AddHours(10).ToUniversalTime(), // Convert to UTC
                    now.AddDays(1).Date.AddHours(11).ToUniversalTime(), // Convert to UTC
                    owner1.Id, 
                    company1.Id),
                    
                new CalendarEvent(
                    "Project Review", 
                    "End of sprint review", 
                    now.AddDays(3).Date.AddHours(14).ToUniversalTime(), // Convert to UTC
                    now.AddDays(3).Date.AddHours(16).ToUniversalTime(), // Convert to UTC
                    employees1[2].Id, 
                    company1.Id)
            };

            var events2 = new List<CalendarEvent>
            {
                new CalendarEvent(
                    "Product Launch", 
                    "New product introduction", 
                    now.AddDays(5).Date.AddHours(9).ToUniversalTime(), // Convert to UTC
                    now.AddDays(5).Date.AddHours(12).ToUniversalTime(), // Convert to UTC
                    owner2.Id, 
                    company2.Id)
            };

            await context.CalendarEvents.AddRangeAsync(events1);
            await context.CalendarEvents.AddRangeAsync(events2);
            
            // Add participants to events
            events1[0].AddParticipant(employees1[0]);
            events1[0].AddParticipant(employees1[1]);
            events1[0].AddParticipant(employees1[2]);
            
            events1[1].AddParticipant(employees1[0]);
            events1[1].AddParticipant(employees1[1]);
            
            events2[0].AddParticipant(employees2[0]);
            events2[0].AddParticipant(employees2[1]);
            
            await context.SaveChangesAsync();
        }
    }
}
