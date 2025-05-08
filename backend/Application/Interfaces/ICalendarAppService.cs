using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Application.DTOs;

namespace Application.Interfaces
{
    public interface ICalendarAppService
    {
        Task<CalendarEventDto> GetEventByIdAsync(Guid id);
        Task<IEnumerable<CalendarEventDto>> GetEventsByCompanyIdAsync(Guid companyId, DateTime? startDate, DateTime? endDate);
        Task<IEnumerable<CalendarEventDto>> GetEventsByEmployeeIdAsync(Guid employeeId, DateTime? startDate, DateTime? endDate);
        Task<CalendarEventDto> CreateEventAsync(Guid companyId, Guid creatorId, CalendarEventCreateDto eventDto);
        Task<CalendarEventDto> UpdateEventAsync(Guid id, CalendarEventUpdateDto eventDto);
        Task<bool> DeleteEventAsync(Guid id);
        Task<CalendarEventDto> AddParticipantToEventAsync(Guid eventId, Guid employeeId);
        Task<bool> RemoveParticipantFromEventAsync(Guid eventId, Guid employeeId);
    }
}
