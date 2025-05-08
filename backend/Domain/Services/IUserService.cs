using System;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.Services
{
    public interface IUserService
    {
        Task<CompanyOwner> RegisterCompanyOwnerAsync(string firstName, string lastName, 
            string email, string password);
            
        Task<User> AuthenticateAsync(string email, string password);
        
        Task<User> GetUserByIdAsync(Guid userId);
        
        Task UpdateUserDetailsAsync(Guid userId, string firstName, string lastName, string email);
        
        Task ChangePasswordAsync(Guid userId, string currentPassword, string newPassword);
    }
}
