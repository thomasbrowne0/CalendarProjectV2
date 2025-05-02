using System.Threading.Tasks;
using CalendarProject.Application.DTOs;

namespace CalendarProject.Application.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponseDto> LoginAsync(UserLoginDto loginDto);
        Task<AuthResponseDto> RegisterCompanyOwnerAsync(UserRegistrationDto registrationDto);
        Task<bool> ValidateTokenAsync(string token);
    }
}
