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
    [Route("api/companies")]
    public class CompanyController : ControllerBase
    {
        private readonly ICompanyAppService _companyService;
        private readonly IEmployeeAppService _employeeService;  // Add this field
        private readonly ILogger<CompanyController> _logger;
        private readonly IUserSessionService _userSessionService;

        public CompanyController(
            ICompanyAppService companyService, 
            IEmployeeAppService employeeService,  // Add this parameter
            ILogger<CompanyController> logger, 
            IUserSessionService userSessionService)
        {
            _companyService = companyService ?? throw new ArgumentNullException(nameof(companyService));
            _employeeService = employeeService ?? throw new ArgumentNullException(nameof(employeeService));  // Initialize it
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _userSessionService = userSessionService ?? throw new ArgumentNullException(nameof(userSessionService));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<CompanyDto>>> GetCompanies([FromHeader(Name = "session-id")] string sessionId)
        {
            // Log the incoming session ID
            _logger.LogInformation($"Get companies request with session ID: {sessionId}");
            
            if (string.IsNullOrEmpty(sessionId))
            {
                _logger.LogWarning("Session ID is missing from request");
                return Unauthorized(new { message = "Missing session ID" });
            }
            
            if (!_userSessionService.TryGetUserId(sessionId, out var userId))
            {
                _logger.LogWarning($"Invalid session ID: {sessionId}");
                return Unauthorized(new { message = "Invalid session ID" });
            }
                
            try
            {
                var companies = await _companyService.GetCompaniesByOwnerIdAsync(userId);
                return Ok(companies);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving companies");
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<CompanyDto>> GetCompany(Guid id, [FromHeader] string sessionId)
        {
            if (!_userSessionService.TryGetUserId(sessionId, out var userId))
                return Unauthorized();
                
            try
            {
                // Check if user is a company owner
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(id, userId);
                
                // Not an owner, check if an employee of this company
                if (!isOwner)
                {
                    var employee = await _employeeService.GetEmployeeByIdAsync(userId);
                    if (employee == null || employee.CompanyId != id)
                    {
                        return Forbid();
                    }
                }

                var company = await _companyService.GetCompanyByIdAsync(id);
                return Ok(company);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving company {CompanyId}", id);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<CompanyDto>> CreateCompany(CompanyCreateDto companyDto, [FromHeader] string sessionId)
        {
            if (!_userSessionService.TryGetUserId(sessionId, out var userId))
                return Unauthorized();

            try
            {
                // Check if user is a company owner (implement this logic in your service)
                bool isCompanyOwner = await _companyService.IsUserCompanyOwner(userId);
                if (!isCompanyOwner)
                    return Forbid();

                var company = await _companyService.CreateCompanyAsync(userId, companyDto);
                return CreatedAtAction(nameof(GetCompany), new { id = company.Id }, company);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating company");
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<CompanyDto>> UpdateCompany(Guid id, CompanyUpdateDto companyDto, [FromHeader] string sessionId)
        {
            if (!_userSessionService.TryGetUserId(sessionId, out var userId))
                return Unauthorized();

            try
            {
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(id, userId);
                
                if (!isOwner)
                {
                    return Forbid();
                }

                var updatedCompany = await _companyService.UpdateCompanyAsync(id, companyDto);
                return Ok(updatedCompany);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating company {CompanyId}", id);
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteCompany(Guid id, [FromHeader] string sessionId)
        {
            if (!_userSessionService.TryGetUserId(sessionId, out var userId))
                return Unauthorized();

            try
            {
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(id, userId);
                
                if (!isOwner)
                {
                    return Forbid();
                }

                var result = await _companyService.DeleteCompanyAsync(id);
                
                if (!result)
                {
                    return NotFound();
                }
                
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting company {CompanyId}", id);
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
