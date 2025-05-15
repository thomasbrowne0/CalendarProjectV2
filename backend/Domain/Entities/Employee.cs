using System;
using System.Collections.Generic;

namespace Domain.Entities
{
    public class Employee : User
    {
        public Guid CompanyId { get; private set; }
        public virtual Company Company { get; private set; }
        public string JobTitle { get; private set; }
<<<<<<< Updated upstream
        public string MobilePhone { get; private set; } 
=======
        public string MobilePhone { get; private set; } // Add this property
>>>>>>> Stashed changes
        public virtual ICollection<CalendarEvent> Events { get; private set; }
        
        // For EF Core
        private Employee() : base() { }
        
        public Employee(string firstName, string lastName, string email, string passwordHash, 
                      Guid companyId, string jobTitle, string mobilePhone = "") 
            : base(firstName, lastName, email, passwordHash)
        {
            CompanyId = companyId;
            JobTitle = jobTitle ?? throw new ArgumentNullException(nameof(jobTitle));
            MobilePhone = mobilePhone ?? "";
            Events = new List<CalendarEvent>();
        }
        
        public void UpdateJobTitle(string jobTitle)
        {
            if (string.IsNullOrWhiteSpace(jobTitle))
                throw new ArgumentException("Job title cannot be empty", nameof(jobTitle));
                
            JobTitle = jobTitle;
        }

        public void UpdateMobilePhone(string mobilePhone)
        {
            MobilePhone = mobilePhone ?? "";
        }
    }
}
