using System;
using System.Threading.Tasks;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.Extensions.Configuration;
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
        private readonly IConfiguration _configuration;

        public AuthService(
            IUserRepository userRepository,
            ICompanyOwnerRepository companyOwnerRepository,
            IUnitOfWork unitOfWork,
            IConfiguration configuration)
        {
            _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
            _companyOwnerRepository = companyOwnerRepository ?? throw new ArgumentNullException(nameof(companyOwnerRepository));
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<AuthResponseDto> LoginAsync(UserLoginDto loginDto)
        {            var user = await _userRepository.GetByEmailAsync(loginDto.Email);
            if (user == null)
                throw new Exception("User not found");

            /* We need to implement proper password hashing using BCrypt or similar
               instead of plain text comparison for production security */
            if (user.PasswordHash != loginDto.Password)
                throw new Exception("Invalid credentials");

            return new AuthResponseDto
            {
                Token = GenerateJwtToken(user),
                User = MapToUserDto(user),
                ExpiresAt = DateTime.UtcNow.AddHours(1)
            };
        }

        public async Task<AuthResponseDto> RegisterCompanyOwnerAsync(UserRegistrationDto registrationDto)
        {
            var exists = await _userRepository.ExistsByEmailAsync(registrationDto.Email);            if (exists)
                throw new Exception("Email already registered");

            /* We need to hash passwords using BCrypt before storing them
               for production security compliance */
            var companyOwner = new CompanyOwner(
                registrationDto.FirstName,
                registrationDto.LastName,
                registrationDto.Email,
                registrationDto.Password
            );

            await _companyOwnerRepository.AddAsync(companyOwner);
            await _unitOfWork.SaveChangesAsync();

            return new AuthResponseDto
            {
                Token = GenerateJwtToken(companyOwner),
                User = MapToUserDto(companyOwner),
                ExpiresAt = DateTime.UtcNow.AddHours(1)
            };
        }

        public Task<bool> ValidateTokenAsync(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Key"] ?? "DefaultSecretKey123!@#");

            try
            {
                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = _configuration["Jwt:Issuer"],
                    ValidateAudience = true,
                    ValidAudience = _configuration["Jwt:Audience"],
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                }, out SecurityToken validatedToken);

                return Task.FromResult(true);
            }
            catch
            {
                return Task.FromResult(false);
            }
        }

        private string GenerateJwtToken(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Key"] ?? "DefaultSecretKey123!@#");
            var userType = user is CompanyOwner ? "CompanyOwner" : "Employee";

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.GivenName, user.FirstName),
                new Claim(ClaimTypes.Surname, user.LastName),
                new Claim("UserType", userType),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())            };

            /* We need to add company context for employees because they should only
               see data within their own company scope */
            if (user is Employee employee)
            {
                var companyClaim = new Claim("CompanyId", employee.CompanyId.ToString());
                claims = claims.Append(companyClaim).ToArray();
            }

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(1),
                Issuer = _configuration["Jwt:Issuer"],
                Audience = _configuration["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
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
