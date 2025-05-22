using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Application.DTOs;
using Application.Interfaces;

namespace API.Controllers
{
    [ApiController]
    [Route("api/companies/{companyId}/events")]
    public class CalendarController : ControllerBase
    {
        private readonly ICalendarAppService _calendarService;
        private readonly ICompanyAppService _companyService;
        private readonly IEmployeeAppService _employeeService;
        private readonly ILogger<CalendarController> _logger;
        private readonly IUserSessionService _sessionService;

        public CalendarController(
            ICalendarAppService calendarService,
            ICompanyAppService companyService,
            IEmployeeAppService employeeService,
            ILogger<CalendarController> logger,
            IUserSessionService sessionService)
        {
            _calendarService = calendarService ?? throw new ArgumentNullException(nameof(calendarService));
            _companyService = companyService ?? throw new ArgumentNullException(nameof(companyService));
            _employeeService = employeeService ?? throw new ArgumentNullException(nameof(employeeService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _sessionService = sessionService ?? throw new ArgumentNullException(nameof(sessionService));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<CalendarEventDto>>> GetEvents(
            Guid companyId, 
            [FromQuery] DateTime? start, 
            [FromQuery] DateTime? end,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                // Use default date range if not provided
                var startDate = start ?? DateTime.UtcNow.Date.AddMonths(-1);
                var endDate = end ?? DateTime.UtcNow.Date.AddMonths(1);

                // Ensure dates are in UTC
                if (startDate.Kind != DateTimeKind.Utc)
                    startDate = DateTime.SpecifyKind(startDate, DateTimeKind.Utc);
                if (endDate.Kind != DateTimeKind.Utc)
                    endDate = DateTime.SpecifyKind(endDate, DateTimeKind.Utc);

                var events = await _calendarService.GetEventsByCompanyIdAsync(companyId, startDate, endDate);
                return Ok(events);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving events for company {CompanyId}", companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("employee/{employeeId}")]
        public async Task<ActionResult<IEnumerable<CalendarEventDto>>> GetEmployeeEvents(
            Guid companyId,
            Guid employeeId,
            [FromQuery] DateTime? start,
            [FromQuery] DateTime? end,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                // Make sure the employee belongs to the company
                var employee = await _employeeService.GetEmployeeByIdAsync(employeeId);
                if (employee == null || employee.CompanyId != companyId)
                {
                    return NotFound();
                }

                var events = await _calendarService.GetEventsByEmployeeIdAsync(employeeId, start, end);
                return Ok(events);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving events for employee {EmployeeId} in company {CompanyId}", employeeId, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<CalendarEventDto>> GetEvent(
            Guid companyId, 
            Guid id,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                var calendarEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (calendarEvent == null || calendarEvent.CompanyId != companyId)
                {
                    return NotFound();
                }
                
                return Ok(calendarEvent);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving event {EventId} for company {CompanyId}", id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<CalendarEventDto>> CreateEvent(
            Guid companyId, 
            CalendarEventCreateDto eventDto,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
        
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                // Ensure dates are in UTC
                if (eventDto.StartTime.Kind != DateTimeKind.Utc)
                    eventDto.StartTime = DateTime.SpecifyKind(eventDto.StartTime, DateTimeKind.Utc);
            
                if (eventDto.EndTime.Kind != DateTimeKind.Utc)
                    eventDto.EndTime = DateTime.SpecifyKind(eventDto.EndTime, DateTimeKind.Utc);

                _logger.LogInformation(
                    "Creating event. Title: {Title}, Start: {Start}, End: {End}, Participants: {Participants}", 
                    eventDto.Title, 
                    eventDto.StartTime, 
                    eventDto.EndTime, 
                    string.Join(", ", eventDto.ParticipantIds ?? new List<Guid>()));
            
                try
                {
                    var calendarEvent = await _calendarService.CreateEventAsync(companyId, userId, eventDto);
                    return CreatedAtAction(nameof(GetEvent), new { companyId = companyId, id = calendarEvent.Id }, calendarEvent);
                }
                catch (Exception innerEx)
                {
                    _logger.LogError(innerEx, "Detailed error creating event");
                    throw; // Re-throw to be caught by outer catch
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating event for company {CompanyId}", companyId);
                return BadRequest(new { message = ex.Message, details = ex.ToString() });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<CalendarEventDto>> UpdateEvent(
            Guid companyId, 
            Guid id, 
            CalendarEventUpdateDto eventDto,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

                // Only allow update if user is the creator or a company owner
                var isOwner = await _companyService.IsUserCompanyOwner(userId);
                if (!isOwner && existingEvent.CreatedById != userId)
                {
                    return Forbid();
                }

                var updatedEvent = await _calendarService.UpdateEventAsync(id, eventDto);
                return Ok(updatedEvent);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating event {EventId} for company {CompanyId}", id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteEvent(
            Guid companyId, 
            Guid id,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

                // Only allow delete if user is the creator or a company owner
                var isOwner = await _companyService.IsUserCompanyOwner(userId);
                if (!isOwner && existingEvent.CreatedById != userId)
                {
                    return Forbid();
                }

                var result = await _calendarService.DeleteEventAsync(id);
                
                if (!result)
                {
                    return NotFound();
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting event {EventId} for company {CompanyId}", id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/participants/{employeeId}")]
        public async Task<ActionResult<CalendarEventDto>> AddParticipant(
            Guid companyId, 
            Guid id, 
            Guid employeeId,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

                // Make sure the employee belongs to the company
                var employee = await _employeeService.GetEmployeeByIdAsync(employeeId);
                if (employee == null || employee.CompanyId != companyId)
                {
                    return NotFound();
                }

                var updatedEvent = await _calendarService.AddParticipantToEventAsync(id, employeeId);
                return Ok(updatedEvent);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding participant {EmployeeId} to event {EventId} in company {CompanyId}", employeeId, id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}/participants/{employeeId}")]
        public async Task<ActionResult> RemoveParticipant(
            Guid companyId, 
            Guid id, 
            Guid employeeId,
            [FromHeader] string sessionId)
        {
            try
            {
                if (!_sessionService.TryGetUserId(sessionId, out var userId))
                    return Unauthorized();
            
                if (!await CanAccessCompany(companyId, userId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

                // Make sure the employee belongs to the company
                var employee = await _employeeService.GetEmployeeByIdAsync(employeeId);
                if (employee == null || employee.CompanyId != companyId)
                {
                    return NotFound();
                }

                var result = await _calendarService.RemoveParticipantFromEventAsync(id, employeeId);
                
                if (!result)
                {
                    return NotFound();
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error removing participant {EmployeeId} from event {EventId} in company {CompanyId}", employeeId, id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        private async Task<bool> CanAccessCompany(Guid companyId, Guid userId)
        {
            // Determine if the user is a company owner
            var isOwner = await _companyService.ValidateCompanyOwnershipAsync(companyId, userId);
            if (isOwner) return true;

            // Or if they're an employee of the company
            return await _employeeService.ValidateEmployeeCompanyMembershipAsync(userId, companyId);
        }
    }
}
