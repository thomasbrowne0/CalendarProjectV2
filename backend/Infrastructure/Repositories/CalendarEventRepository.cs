using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;
using Domain.IRepositories;
using Infrastructure.Data;
using Infrastructure.Data;

namespace Infrastructure.Repositories
{
    public class CalendarEventRepository : Repository<CalendarEvent>, ICalendarEventRepository
    {
        public CalendarEventRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<IEnumerable<CalendarEvent>> GetEventsByCompanyIdAsync(Guid companyId)
        {
            return await _dbSet
                .Include(e => e.CreatedBy)
                .Where(e => e.CompanyId == companyId)
                .ToListAsync();
        }

        public async Task<IEnumerable<CalendarEvent>> GetEventsByEmployeeIdAsync(Guid employeeId)
        {
            return await _dbSet
                .Include(e => e.CreatedBy)
                .Include(e => e.Participants)
                .Where(e => e.Participants.Any(p => p.Id == employeeId))
                .ToListAsync();
        }

        public async Task<IEnumerable<CalendarEvent>> GetEventsByDateRangeAsync(Guid companyId, DateTime start, DateTime end)
        {
            return await _dbSet
                .Include(e => e.CreatedBy)
                .Include(e => e.Participants)
                .Where(e => e.CompanyId == companyId &&
                           (e.StartTime <= end && e.EndTime >= start))
                .ToListAsync();
        }

        public async Task<CalendarEvent> GetEventWithParticipantsAsync(Guid eventId)
        {
            var calendarEvent = await _dbSet
                .Include(e => e.CreatedBy)
                .Include(e => e.Participants)
                .FirstOrDefaultAsync(e => e.Id == eventId);
                
            if (calendarEvent == null)
                throw new KeyNotFoundException($"Calendar event with ID {eventId} not found");
                
            return calendarEvent;
        }
    }
}
