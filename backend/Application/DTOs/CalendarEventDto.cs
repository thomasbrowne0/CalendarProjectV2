using System;
using System.Collections.Generic;

namespace Application.DTOs
{
    public class CalendarEventDto
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public Guid CreatedById { get; set; }
        public string CreatedByName { get; set; } = string.Empty;
        public Guid CompanyId { get; set; }
        public List<EmployeeDto> Participants { get; set; } = new List<EmployeeDto>();
    }

    public class CalendarEventCreateDto
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        
        private DateTime _startTime;
        public DateTime StartTime 
        { 
            get => _startTime;
            set => _startTime = value.Kind == DateTimeKind.Unspecified 
                ? DateTime.SpecifyKind(value, DateTimeKind.Utc) 
                : value;
        }
        
        private DateTime _endTime;
        public DateTime EndTime 
        { 
            get => _endTime;
            set => _endTime = value.Kind == DateTimeKind.Unspecified 
                ? DateTime.SpecifyKind(value, DateTimeKind.Utc) 
                : value;
        }
        
        public List<Guid> ParticipantIds { get; set; } = new List<Guid>();
    }

    public class CalendarEventUpdateDto
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public List<Guid> ParticipantIds { get; set; } = new List<Guid>();
    }
}
