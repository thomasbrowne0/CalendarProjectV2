using System;
using System.Collections.Generic;

namespace Domain.Entities
{
    public class CalendarEvent
    {
        public Guid Id { get; private set; }
        public string Title { get; private set; }
        public string Description { get; private set; }
        public DateTime StartTime { get; private set; }
        public DateTime EndTime { get; private set; }
        public Guid CreatedById { get; private set; }
        public virtual User CreatedBy { get; private set; }
        public Guid CompanyId { get; private set; }
        public virtual Company Company { get; private set; }
        public virtual ICollection<Employee> Participants { get; private set; }        private CalendarEvent() { }
        
        public CalendarEvent(string title, string description, DateTime startTime, DateTime endTime,
                            Guid createdById, Guid companyId)
        {
            if (string.IsNullOrWhiteSpace(title))
                throw new ArgumentException("Event title cannot be empty", nameof(title));
            
            if (startTime >= endTime)
                throw new ArgumentException("End time must be after start time", nameof(endTime));
            
            Id = Guid.NewGuid();
            Title = title;
            Description = description ?? string.Empty;
            StartTime = startTime;
            EndTime = endTime;
            CreatedById = createdById;
            CompanyId = companyId;
            Participants = new List<Employee>();
        }
        
        public void UpdateEventDetails(string title, string description, DateTime? startTime, DateTime? endTime)
        {
            if (!string.IsNullOrWhiteSpace(title))
                Title = title;
                
            if (description != null)
                Description = description;
                
            if (startTime.HasValue && endTime.HasValue)
            {
                if (startTime.Value >= endTime.Value)
                    throw new ArgumentException("End time must be after start time");
                    
                StartTime = startTime.Value;
                EndTime = endTime.Value;
            }
            else if (startTime.HasValue)
            {
                if (startTime.Value >= EndTime)
                    throw new ArgumentException("Start time must be before current end time");
                    
                StartTime = startTime.Value;
            }
            else if (endTime.HasValue)
            {
                if (StartTime >= endTime.Value)
                    throw new ArgumentException("End time must be after current start time");
                    
                EndTime = endTime.Value;
            }
        }
          /*
         * We need to enforce company boundary here because employees from different
         * companies shouldn't be able to participate in each other's events
         */
        public void AddParticipant(Employee employee)
        {
            if (employee == null)
                throw new ArgumentNullException(nameof(employee));
                
            if (employee.CompanyId != CompanyId)
                throw new InvalidOperationException("Employee must belong to the same company as the event");
                
            if (!Participants.Contains(employee))
                Participants.Add(employee);
        }
        
        public void RemoveParticipant(Employee employee)
        {
            if (employee == null)
                throw new ArgumentNullException(nameof(employee));
                
            Participants.Remove(employee);
        }
    }
}
