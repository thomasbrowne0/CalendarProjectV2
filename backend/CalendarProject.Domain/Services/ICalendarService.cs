using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CalendarProject.Domain.Entities;

namespace CalendarProject.Domain.Services
{
    public interface ICalendarService
    {
        Task<CalendarEvent> CreateEventAsync(string title, string description, 
            DateTime startTime, DateTime endTime, Guid createdById, Guid companyId);
        
        Task<CalendarEvent> UpdateEventAsync(Guid eventId, string title, string description, 
            DateTime? startTime, DateTime? endTime);
            
        Task AddParticipantToEventAsync(Guid eventId, Guid employeeId);
        
        Task RemoveParticipantFromEventAsync(Guid eventId, Guid employeeId);
        
        Task<IEnumerable<CalendarEvent>> GetCompanyEventsForDateRangeAsync(Guid companyId, 
            DateTime startDate, DateTime endDate);
            
        Task<IEnumerable<CalendarEvent>> GetEmployeeEventsForDateRangeAsync(Guid employeeId, 
            DateTime startDate, DateTime endDate);
    }
}
