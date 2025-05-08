using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.IRepositories
{
    public interface ICalendarEventRepository : IRepository<CalendarEvent>
    {
        Task<IEnumerable<CalendarEvent>> GetEventsByCompanyIdAsync(Guid companyId);
        Task<IEnumerable<CalendarEvent>> GetEventsByEmployeeIdAsync(Guid employeeId);
        Task<IEnumerable<CalendarEvent>> GetEventsByDateRangeAsync(Guid companyId, DateTime start, DateTime end);
        Task<CalendarEvent> GetEventWithParticipantsAsync(Guid eventId);
    }
}
