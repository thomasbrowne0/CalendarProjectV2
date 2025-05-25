using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;
using Domain.IRepositories;
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
            return await _context.CalendarEvents
                .Where(e => e.CompanyId == companyId)
                .Include(e => e.Participants)
                .OrderBy(e => e.StartTime)
                .ToListAsync();
        }

        public async Task<IEnumerable<CalendarEvent>> GetEventsByEmployeeIdAsync(Guid employeeId)
        {
            return await _context.CalendarEvents
                .Where(e => e.Participants.Any(p => p.Id == employeeId))
                .Include(e => e.Participants)
                .OrderBy(e => e.StartTime)
                .ToListAsync();
        }

        /*
         * We need this complex date range query because events can span multiple days,
         * so we must check if they overlap with the requested range in any way
         */
        public async Task<IEnumerable<CalendarEvent>> GetEventsByDateRangeAsync(Guid companyId, DateTime start, DateTime end)
        {
            return await _context.CalendarEvents
                .Where(e => e.CompanyId == companyId &&
                            ((e.StartTime >= start && e.StartTime <= end) || 
                             (e.EndTime >= start && e.EndTime <= end) ||
                             (e.StartTime <= start && e.EndTime >= end)))
                .Include(e => e.Participants)
                .OrderBy(e => e.StartTime)
                .ToListAsync();
        }

        /*
         * We need to eagerly load all related entities here because this is typically
         * used for event detail views where complete information is required
         */
        public async Task<CalendarEvent> GetEventWithParticipantsAsync(Guid eventId)
        {
            return await _context.CalendarEvents
                .Include(e => e.Participants)
                .Include(e => e.CreatedBy)
                .Include(e => e.Company)
                .FirstOrDefaultAsync(e => e.Id == eventId);
        }
    }
}