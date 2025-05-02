using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using CalendarProject.Application.DTOs;
using CalendarProject.Application.Interfaces;

namespace CalendarProject.API.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService ?? throw new ArgumentNullException(nameof(authService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [HttpPost("login")]
        public async Task<ActionResult<AuthResponseDto>> Login(UserLoginDto loginDto)
        {
            try
            {
                var result = await _authService.LoginAsync(loginDto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during login attempt for {Email}", loginDto.Email);
                return BadRequest(new { message = "Invalid login attempt" });
            }
        }

        [HttpPost("register-company-owner")]
        public async Task<ActionResult<AuthResponseDto>> RegisterCompanyOwner(UserRegistrationDto registrationDto)
        {
            try
            {
                var result = await _authService.RegisterCompanyOwnerAsync(registrationDto);
                return CreatedAtAction(nameof(Login), result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for {Email}", registrationDto.Email);
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
