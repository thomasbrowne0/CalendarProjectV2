using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using CalendarProject.Application.DTOs;
using CalendarProject.Application.Interfaces;

namespace CalendarProject.API.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/companies/{companyId}/employees")]
    public class EmployeeController : ControllerBase
    {
        private readonly IEmployeeAppService _employeeService;
        private readonly ICompanyAppService _companyService;
        private readonly ILogger<EmployeeController> _logger;

        public EmployeeController(
            IEmployeeAppService employeeService, 
            ICompanyAppService companyService, 
            ILogger<EmployeeController> logger)
        {
            _employeeService = employeeService ?? throw new ArgumentNullException(nameof(employeeService));
            _companyService = companyService ?? throw new ArgumentNullException(nameof(companyService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<EmployeeDto>>> GetEmployees(Guid companyId)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var employees = await _employeeService.GetEmployeesByCompanyIdAsync(companyId);
                return Ok(employees);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving employees for company {CompanyId}", companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<EmployeeDto>> GetEmployee(Guid companyId, Guid id)
        {
            try
            {
                if (!await CanAccessCompany(companyId))
                {
                    return Forbid();
                }

                var employee = await _employeeService.GetEmployeeByIdAsync(id);
                
                if (employee.CompanyId != companyId)
                {
                    return NotFound();
                }
                
                return Ok(employee);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving employee {EmployeeId} for company {CompanyId}", id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost]
        [Authorize(Policy = "CompanyOwnerOnly")]
        public async Task<ActionResult<EmployeeDto>> CreateEmployee(Guid companyId, EmployeeCreateDto employeeDto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(companyId, userId);
                
                if (!isOwner)
                {
                    return Forbid();
                }

                var employee = await _employeeService.CreateEmployeeAsync(companyId, employeeDto);
                return CreatedAtAction(nameof(GetEmployee), new { companyId = companyId, id = employee.Id }, employee);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating employee for company {CompanyId}", companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "CompanyOwnerOnly")]
        public async Task<ActionResult<EmployeeDto>> UpdateEmployee(Guid companyId, Guid id, EmployeeUpdateDto employeeDto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(companyId, userId);
                
                if (!isOwner)
                {
                    return Forbid();
                }

                var employee = await _employeeService.GetEmployeeByIdAsync(id);
                
                if (employee == null || employee.CompanyId != companyId)
                {
                    return NotFound();
                }

                var updatedEmployee = await _employeeService.UpdateEmployeeAsync(id, employeeDto);
                return Ok(updatedEmployee);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating employee {EmployeeId} for company {CompanyId}", id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "CompanyOwnerOnly")]
        public async Task<ActionResult> DeleteEmployee(Guid companyId, Guid id)
        {
            try
            {
                var userId = GetCurrentUserId();
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(companyId, userId);
                
                if (!isOwner)
                {
                    return Forbid();
                }

                var employee = await _employeeService.GetEmployeeByIdAsync(id);
                
                if (employee == null || employee.CompanyId != companyId)
                {
                    return NotFound();
                }

                var result = await _employeeService.DeleteEmployeeAsync(id);
                
                if (!result)
                {
                    return NotFound();
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting employee {EmployeeId} for company {CompanyId}", id, companyId);
                return BadRequest(new { message = ex.Message });
            }
        }

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
