using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Application.DTOs;
using Application.Interfaces;
using Domain.Entities;
using Domain.IRepositories;
using Domain.IServices;

namespace Application.Services
{
    public class CalendarAppService : ICalendarAppService
    {
        private readonly ICalendarEventRepository _eventRepository;
        private readonly IEmployeeRepository _employeeRepository;
        private readonly ICompanyRepository _companyRepository;
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IWebSocketService _webSocketService;

        public CalendarAppService(
            ICalendarEventRepository eventRepository,
            IEmployeeRepository employeeRepository,
            ICompanyRepository companyRepository,
            IUserRepository userRepository,
            IUnitOfWork unitOfWork,
            IWebSocketService webSocketService)
        {
            _eventRepository = eventRepository ?? throw new ArgumentNullException(nameof(eventRepository));
            _employeeRepository = employeeRepository ?? throw new ArgumentNullException(nameof(employeeRepository));
            _companyRepository = companyRepository ?? throw new ArgumentNullException(nameof(companyRepository));
            _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
            _webSocketService = webSocketService ?? throw new ArgumentNullException(nameof(webSocketService));
        }

        public async Task<CalendarEventDto> GetEventByIdAsync(Guid id)
        {
            var calendarEvent = await _eventRepository.GetEventWithParticipantsAsync(id);
            if (calendarEvent == null)
                throw new Exception($"Event with ID {id} not found");

            return MapToCalendarEventDto(calendarEvent);
        }

        public async Task<IEnumerable<CalendarEventDto>> GetEventsByCompanyIdAsync(Guid companyId, DateTime? startDate, DateTime? endDate)
        {
            IEnumerable<CalendarEvent> events;

            if (startDate.HasValue && endDate.HasValue)
            {
                events = await _eventRepository.GetEventsByDateRangeAsync(companyId, startDate.Value, endDate.Value);
            }
            else
            {
                events = await _eventRepository.GetEventsByCompanyIdAsync(companyId);
            }

            return events.Select(MapToCalendarEventDto);
        }

        public async Task<IEnumerable<CalendarEventDto>> GetEventsByEmployeeIdAsync(Guid employeeId, DateTime? startDate, DateTime? endDate)
        {            var events = await _eventRepository.GetEventsByEmployeeIdAsync(employeeId);
            
            if (startDate.HasValue && endDate.HasValue)
            {
                events = events.Where(e => e.StartTime <= endDate.Value && e.EndTime >= startDate.Value);
            }
            
            return events.Select(MapToCalendarEventDto);
        }        public async Task<CalendarEventDto> CreateEventAsync(Guid companyId, Guid creatorId, CalendarEventCreateDto eventDto)
        {
            var company = await _companyRepository.GetByIdAsync(companyId);
            if (company == null)
                throw new Exception($"Company with ID {companyId} not found");

            var creator = await _userRepository.GetByIdAsync(creatorId);
            if (creator == null)
                throw new Exception($"User with ID {creatorId} not found");

            /* We need to ensure all event times are stored in UTC to avoid timezone
               confusion when displaying events across different user locations */
            if (eventDto.StartTime.Kind != DateTimeKind.Utc)
                eventDto.StartTime = DateTime.SpecifyKind(eventDto.StartTime, DateTimeKind.Utc);
                
            if (eventDto.EndTime.Kind != DateTimeKind.Utc)
                eventDto.EndTime = DateTime.SpecifyKind(eventDto.EndTime, DateTimeKind.Utc);

            var calendarEvent = new CalendarEvent(
                eventDto.Title,
                eventDto.Description,
                eventDto.StartTime,
                eventDto.EndTime,
                creatorId,
                companyId
            );            try
            {
                /* We need to validate that participants belong to the same company
                   to maintain data isolation between different organizations */
                if (eventDto.ParticipantIds != null && eventDto.ParticipantIds.Any())
                {
                    foreach (var participantId in eventDto.ParticipantIds)
                    {
                        var employee = await _employeeRepository.GetByIdAsync(participantId);
                        if (employee != null && employee.CompanyId == companyId)
                        {
                            calendarEvent.AddParticipant(employee);
                        }
                    }
                }

                await _eventRepository.AddAsync(calendarEvent);
                await _unitOfWork.SaveChangesAsync();

                /* We need WebSocket notifications to provide real-time updates
                   when events are created so all connected users see changes immediately */
                await _webSocketService.NotifyEventCreatedAsync(companyId, calendarEvent.Id);

                return MapToCalendarEventDto(calendarEvent);
            }
            catch (Exception ex)
            {
                throw new Exception($"Error creating event: {ex.Message}", ex);
            }
        }

        public async Task<CalendarEventDto> UpdateEventAsync(Guid id, CalendarEventUpdateDto eventDto)
        {
            var calendarEvent = await _eventRepository.GetEventWithParticipantsAsync(id);            if (calendarEvent == null)
                throw new Exception($"Event with ID {id} not found");

            calendarEvent.UpdateEventDetails(
                eventDto.Title,
                eventDto.Description,
                eventDto.StartTime,
                eventDto.EndTime
            );

            /* We need to handle participant updates separately because they require
               validation to ensure all participants belong to the same company */
            if (eventDto.ParticipantIds != null)
            {
                var currentParticipantIds = calendarEvent.Participants.Select(p => p.Id).ToList();
                
                var participantsToAdd = eventDto.ParticipantIds.Except(currentParticipantIds);
                var participantsToRemove = currentParticipantIds.Except(eventDto.ParticipantIds);

                foreach (var participantId in participantsToAdd)
                {
                    var employee = await _employeeRepository.GetByIdAsync(participantId);
                    if (employee != null && employee.CompanyId == calendarEvent.CompanyId)
                    {
                        calendarEvent.AddParticipant(employee);                    }
                }

                foreach (var participantId in participantsToRemove)
                {
                    var employee = calendarEvent.Participants.FirstOrDefault(p => p.Id == participantId);
                    if (employee != null)
                    {
                        calendarEvent.RemoveParticipant(employee);
                    }
                }
            }

            await _eventRepository.UpdateAsync(calendarEvent);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyEventUpdatedAsync(calendarEvent.CompanyId, calendarEvent.Id);

            return MapToCalendarEventDto(calendarEvent);
        }

        public async Task<bool> DeleteEventAsync(Guid id)
        {
            var calendarEvent = await _eventRepository.GetByIdAsync(id);
            if (calendarEvent == null)
                return false;

            var companyId = calendarEvent.CompanyId;
              await _eventRepository.DeleteAsync(calendarEvent);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyEventDeletedAsync(companyId, id);

            return true;
        }

        public async Task<CalendarEventDto> AddParticipantToEventAsync(Guid eventId, Guid employeeId)
        {
            var calendarEvent = await _eventRepository.GetEventWithParticipantsAsync(eventId);
            if (calendarEvent == null)
                throw new Exception($"Event with ID {eventId} not found");

            var employee = await _employeeRepository.GetByIdAsync(employeeId);
            if (employee == null)
                throw new Exception($"Employee with ID {employeeId} not found");

            if (employee.CompanyId != calendarEvent.CompanyId)
                throw new Exception("Employee does not belong to the same company as the event");            calendarEvent.AddParticipant(employee);
            
            await _eventRepository.UpdateAsync(calendarEvent);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyEventUpdatedAsync(calendarEvent.CompanyId, calendarEvent.Id);

            return MapToCalendarEventDto(calendarEvent);
        }

        public async Task<bool> RemoveParticipantFromEventAsync(Guid eventId, Guid employeeId)
        {
            var calendarEvent = await _eventRepository.GetEventWithParticipantsAsync(eventId);
            if (calendarEvent == null)
                return false;

            var employee = calendarEvent.Participants.FirstOrDefault(p => p.Id == employeeId);
            if (employee == null)
                return false;            calendarEvent.RemoveParticipant(employee);
            
            await _eventRepository.UpdateAsync(calendarEvent);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyEventUpdatedAsync(calendarEvent.CompanyId, calendarEvent.Id);

            return true;
        }

        private CalendarEventDto MapToCalendarEventDto(CalendarEvent calendarEvent)
        {
            return new CalendarEventDto
            {
                Id = calendarEvent.Id,
                Title = calendarEvent.Title,
                Description = calendarEvent.Description,
                StartTime = calendarEvent.StartTime,
                EndTime = calendarEvent.EndTime,
                CreatedById = calendarEvent.CreatedById,
                CreatedByName = calendarEvent.CreatedBy?.FirstName + " " + calendarEvent.CreatedBy?.LastName,
                CompanyId = calendarEvent.CompanyId,
                Participants = calendarEvent.Participants?
                    .Select(p => new EmployeeDto
                    {
                        Id = p.Id,
                        FirstName = p.FirstName,
                        LastName = p.LastName,
                        Email = p.Email,
                        JobTitle = p.JobTitle,
                        CompanyId = p.CompanyId
                    })
                    .ToList() ?? new List<EmployeeDto>()
            };
        }
    }
}
