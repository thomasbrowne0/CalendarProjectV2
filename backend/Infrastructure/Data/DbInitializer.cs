using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;

namespace Infrastructure.Data
{
    public static class DbInitializer
    {        public static async Task SeedAsync(AppDbContext context)
        {
            await context.Database.EnsureCreatedAsync();

            if (await context.Users.AnyAsync())
            {
                return;
            }

            /* We need to use proper password hashing in production instead of 
               plain text passwords for security compliance */
            var owner1 = new CompanyOwner(
                "John", 
                "Smith", 
                "owner@example.com", 
                "Password123");

            var owner2 = new CompanyOwner(
                "Sarah", 
                "Johnson", 
                "sarah@example.com", 
                "Password123");

            await context.CompanyOwners.AddRangeAsync(owner1, owner2);
            await context.SaveChangesAsync();

            var company1 = new Company("Acme Corp", "123456789", owner1.Id);
            var company2 = new Company("Tech Solutions", "987654321", owner2.Id);
            
            await context.Companies.AddRangeAsync(company1, company2);            await context.SaveChangesAsync();

            var employees1 = new List<Employee>
            {
                new Employee("Michael", "Brown", "michael@acme.com", "Password123", company1.Id, "Developer"),
                new Employee("Emma", "Davis", "emma@acme.com", "Password123", company1.Id, "Designer"),
                new Employee("David", "Wilson", "david@acme.com", "Password123", company1.Id, "Project Manager")
            };

            var employees2 = new List<Employee>
            {
                new Employee("Robert", "Jones", "robert@techsolutions.com", "Password123", company2.Id, "Engineer"),
                new Employee("Jennifer", "Garcia", "jennifer@techsolutions.com", "Password123", company2.Id, "QA Analyst")
            };

            await context.Employees.AddRangeAsync(employees1);
            await context.Employees.AddRangeAsync(employees2);
            await context.SaveChangesAsync();

            /* We need to use UTC for all calendar events to ensure consistent
               time handling across different timezones */
            var now = DateTime.UtcNow;
            
            var events1 = new List<CalendarEvent>
            {
                new CalendarEvent(
                    "Team Meeting", 
                    "Weekly team sync", 
                    now.AddDays(1).Date.AddHours(10).ToUniversalTime(),
                    now.AddDays(1).Date.AddHours(11).ToUniversalTime(),
                    owner1.Id, 
                    company1.Id),
                    
                new CalendarEvent(
                    "Project Review", 
                    "End of sprint review",                    now.AddDays(3).Date.AddHours(14).ToUniversalTime(),
                    now.AddDays(3).Date.AddHours(16).ToUniversalTime(),
                    employees1[2].Id, 
                    company1.Id)
            };

            var events2 = new List<CalendarEvent>
            {
                new CalendarEvent(
                    "Product Launch", 
                    "New product introduction",                    now.AddDays(5).Date.AddHours(9).ToUniversalTime(),
                    now.AddDays(5).Date.AddHours(12).ToUniversalTime(),
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
