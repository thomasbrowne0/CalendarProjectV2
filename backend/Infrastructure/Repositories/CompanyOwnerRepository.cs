using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;
using Domain.Repositories;
using Infrastructure.Data;

namespace Infrastructure.Repositories
{
    public class CompanyOwnerRepository : Repository<CompanyOwner>, ICompanyOwnerRepository
    {
        public CompanyOwnerRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<CompanyOwner> GetByIdWithCompaniesAsync(Guid id)
        {
            var owner = await _dbSet
                .Include(o => o.OwnedCompanies)
                .FirstOrDefaultAsync(o => o.Id == id);
                
            if (owner == null)
                throw new KeyNotFoundException($"Company owner with ID {id} not found");
                
            return owner;
        }

        public async Task<CompanyOwner> GetByEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
                
            var owner = await _dbSet
                .FirstOrDefaultAsync(o => o.Email.ToLower() == email.ToLower());
                
            if (owner == null)
                throw new KeyNotFoundException($"Company owner with email {email} not found");
                
            return owner;
        }
    }
}
