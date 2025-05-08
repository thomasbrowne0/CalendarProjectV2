using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;
using Domain.Repositories;
using Infrastructure.Data;

namespace Infrastructure.Repositories
{
    public class UserRepository : Repository<User>, IUserRepository
    {
        public UserRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<User> GetByEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
                
            var user = await _dbSet
                .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
                
            if (user == null)
                throw new KeyNotFoundException($"User with email {email} not found");
                
            return user;
        }

        public async Task<bool> ExistsByEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
                
            return await _dbSet
                .AnyAsync(u => u.Email.ToLower() == email.ToLower());
        }
    }
}
