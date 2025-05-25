using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Application.DTOs;
using Application.Interfaces;

namespace API.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/companies/{companyId}/events")]
    public class CalendarController : ControllerBase
    {
        private readonly ICalendarAppService _calendarService;
        private readonly ICompanyAppService _companyService;
        private readonly IEmployeeAppService _employeeService;
        private readonly ILogger<CalendarController> _logger;

        public CalendarController(
            ICalendarAppService calendarService,
            ICompanyAppService companyService,
            IEmployeeAppService employeeService,
            ILogger<CalendarController> logger)
        {
            _calendarService = calendarService ?? throw new ArgumentNullException(nameof(calendarService));
            _companyService = companyService ?? throw new ArgumentNullException(nameof(companyService));
            _employeeService = employeeService ?? throw new ArgumentNullException(nameof(employeeService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }  
        
        [HttpGet]
        /* We need this to handle date range filtering with sensible defaults because clients 
           might not always specify date ranges and we want to prevent loading too much data */
        public async Task<ActionResult<IEnumerable<CalendarEventDto>>> GetEvents(
            Guid companyId, 
            [FromQuery] DateTime? start, 
            [FromQuery] DateTime? end)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var startDate = start ?? DateTime.UtcNow.Date.AddMonths(-1);
                var endDate = end ?? DateTime.UtcNow.Date.AddMonths(1);

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
        /* We need this validation to prevent data leakage between companies because 
           employee IDs alone aren't enough to ensure proper authorization */
        public async Task<ActionResult<IEnumerable<CalendarEventDto>>> GetEmployeeEvents(
            Guid companyId,
            Guid employeeId,
            [FromQuery] DateTime? start,
            [FromQuery] DateTime? end)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

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
        public async Task<ActionResult<CalendarEventDto>> GetEvent(Guid companyId, Guid id)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
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
        /* We need this complex validation because events must be properly timezone-normalized
           and we require detailed logging for debugging calendar creation issues */
        public async Task<ActionResult<CalendarEventDto>> CreateEvent(Guid companyId, CalendarEventCreateDto eventDto)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                if (eventDto.StartTime.Kind != DateTimeKind.Utc)
                    eventDto.StartTime = DateTime.SpecifyKind(eventDto.StartTime, DateTimeKind.Utc);
                    
                if (eventDto.EndTime.Kind != DateTimeKind.Utc)
                    eventDto.EndTime = DateTime.SpecifyKind(eventDto.EndTime, DateTimeKind.Utc);

                var userId = GetCurrentUserId();
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
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating event for company {CompanyId}", companyId);
                return BadRequest(new { message = ex.Message, details = ex.ToString() });
            }
        }     
        

        [HttpPut("{id}")]
        /* We need this authorization check because only event creators or company owners
           should be able to modify events to maintain data integrity */
        public async Task<ActionResult<CalendarEventDto>> UpdateEvent(Guid companyId, Guid id, CalendarEventUpdateDto eventDto)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

                var userId = GetCurrentUserId();
                var userType = User.FindFirst("UserType")?.Value;
                
                if (userType != "CompanyOwner" && existingEvent.CreatedById != userId)
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
        /* We need this same authorization pattern as updates because deleting events
           should follow the same security model as modifying them */
        public async Task<ActionResult> DeleteEvent(Guid companyId, Guid id)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

                var userId = GetCurrentUserId();
                var userType = User.FindFirst("UserType")?.Value;
                
                if (userType != "CompanyOwner" && existingEvent.CreatedById != userId)
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
        /* We need this double validation to ensure participants can only be added to events
           within their own company and that the employee actually exists */
        public async Task<ActionResult<CalendarEventDto>> AddParticipant(Guid companyId, Guid id, Guid employeeId)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

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
        public async Task<ActionResult> RemoveParticipant(Guid companyId, Guid id, Guid employeeId)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var existingEvent = await _calendarService.GetEventByIdAsync(id);
                
                if (existingEvent == null || existingEvent.CompanyId != companyId)
                {
                    return NotFound();
                }

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
        }        /* We need this complex authorization logic because different user types
           have different access patterns and we must prevent cross-company data access */
        private async Task<bool> CanAccessCompany(Guid companyId)
        {
            var userId = GetCurrentUserId();
            var userType = User.FindFirst("UserType")?.Value;

            if (userType == "CompanyOwner")
            {
                return await _companyService.ValidateCompanyOwnershipAsync(companyId, userId);
            }
            else if (userType == "Employee")
            {
                return await _employeeService.ValidateEmployeeCompanyMembershipAsync(userId, companyId);
            }

            return false;
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            {
                throw new Exception("User ID not found in claims");
            }
            
            return userId;
        }
    }
}
