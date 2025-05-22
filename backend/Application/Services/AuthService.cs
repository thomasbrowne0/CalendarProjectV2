using System;
using System.Threading.Tasks;
using Application.DTOs;
using Application.Interfaces;
using Domain.Entities;
using Domain.IRepositories;
using Domain.IServices;

namespace Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly ICompanyOwnerRepository _companyOwnerRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IUserSessionService _sessionService;

        public AuthService(
            IUserRepository userRepository,
            ICompanyOwnerRepository companyOwnerRepository,
            IUnitOfWork unitOfWork,
            IUserSessionService sessionService)
        {
            _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
            _companyOwnerRepository = companyOwnerRepository ?? throw new ArgumentNullException(nameof(companyOwnerRepository));
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
            _sessionService = sessionService ?? throw new ArgumentNullException(nameof(sessionService));
        }

        public async Task<AuthResponseDto> LoginAsync(UserLoginDto loginDto)
        {
            try
            {
                var user = await _userRepository.GetByEmailAsync(loginDto.Email);
                if (user == null)
                    throw new Exception("User not found");

                // Simple password verification - ensuring it works for both company owners and employees
                // Note: In a real app, you should use proper password hashing
                if (user.PasswordHash != loginDto.Password)
                    throw new Exception("Invalid credentials");

                // Create a session for the user
                string sessionId = _sessionService.CreateSession(user.Id);
                
                // Prepare response
                var response = new AuthResponseDto
                {
                    SessionId = sessionId,
                    User = MapToUserDto(user)
                };
                
                // If the user is an employee, include their company ID
                if (user is Employee employee && employee.CompanyId != Guid.Empty)
                {
                    response.CompanyId = employee.CompanyId.ToString();
                }

                return response;
            }
            catch (Exception ex)
            {
                // Add logging here for debugging
                Console.WriteLine($"Login error: {ex.Message}");
                throw; // Re-throw to propagate to the controller
            }
        }

        public async Task<AuthResponseDto> RegisterCompanyOwnerAsync(UserRegistrationDto registrationDto)
        {
            var exists = await _userRepository.ExistsByEmailAsync(registrationDto.Email);
            if (exists)
                throw new Exception("Email already registered");

            // In a real app, you'd hash the password before storing
            var companyOwner = new CompanyOwner(
                registrationDto.FirstName,
                registrationDto.LastName,
                registrationDto.Email,
                registrationDto.Password
            );

            await _companyOwnerRepository.AddAsync(companyOwner);
            await _unitOfWork.SaveChangesAsync();

            // Create a session for the newly registered user
            string sessionId = _sessionService.CreateSession(companyOwner.Id);

            return new AuthResponseDto
            {
                SessionId = sessionId,
                User = MapToUserDto(companyOwner)
            };
        }

        private UserDto MapToUserDto(User user)
        {
            var userType = user is CompanyOwner ? "CompanyOwner" : "Employee";

            return new UserDto
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                UserType = userType
            };
        }
    }
}
