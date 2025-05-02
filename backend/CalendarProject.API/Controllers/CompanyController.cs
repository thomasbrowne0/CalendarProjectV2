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
    [Route("api/companies")]
    public class CompanyController : ControllerBase
    {
        private readonly ICompanyAppService _companyService;
        private readonly ILogger<CompanyController> _logger;

        public CompanyController(ICompanyAppService companyService, ILogger<CompanyController> logger)
        {
            _companyService = companyService ?? throw new ArgumentNullException(nameof(companyService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<CompanyDto>>> GetCompanies()
        {
            try
            {
                var ownerId = GetCurrentUserId();
                var companies = await _companyService.GetCompaniesByOwnerIdAsync(ownerId);
                return Ok(companies);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving companies");
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<CompanyDto>> GetCompany(Guid id)
        {
            try
            {
                var userId = GetCurrentUserId();
                var userType = User.FindFirst("UserType")?.Value;

                // If user is an employee, check if they belong to the company
                if (userType == "Employee")
                {
                    var companyIdClaim = User.FindFirst("CompanyId")?.Value;
                    if (!Guid.TryParse(companyIdClaim, out var companyId) || companyId != id)
                    {
                        return Forbid();
                    }
                }
                // If user is a company owner, check if they own the company
                else if (userType == "CompanyOwner")
                {
                    var isOwner = await _companyService.ValidateCompanyOwnershipAsync(id, userId);
                    if (!isOwner)
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
        [Authorize(Policy = "CompanyOwnerOnly")]
        public async Task<ActionResult<CompanyDto>> CreateCompany(CompanyCreateDto companyDto)
        {
            try
            {
                var ownerId = GetCurrentUserId();
                var company = await _companyService.CreateCompanyAsync(ownerId, companyDto);
                return CreatedAtAction(nameof(GetCompany), new { id = company.Id }, company);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating company");
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "CompanyOwnerOnly")]
        public async Task<ActionResult<CompanyDto>> UpdateCompany(Guid id, CompanyUpdateDto companyDto)
        {
            try
            {
                var ownerId = GetCurrentUserId();
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(id, ownerId);
                
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
        [Authorize(Policy = "CompanyOwnerOnly")]
        public async Task<ActionResult> DeleteCompany(Guid id)
        {
            try
            {
                var ownerId = GetCurrentUserId();
                var isOwner = await _companyService.ValidateCompanyOwnershipAsync(id, ownerId);
                
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
