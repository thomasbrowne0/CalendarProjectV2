using System.Threading.Tasks;
using Application.DTOs;

namespace Application.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponseDto> LoginAsync(UserLoginDto loginDto);
        Task<AuthResponseDto> RegisterCompanyOwnerAsync(UserRegistrationDto registrationDto);
    }
}
