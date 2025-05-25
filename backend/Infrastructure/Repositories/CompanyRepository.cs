using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Domain.Entities;
using Domain.IRepositories;
using Infrastructure.Data;

namespace Infrastructure.Repositories
{
    public class CompanyRepository : Repository<Company>, ICompanyRepository
    {
        public CompanyRepository(AppDbContext context) : base(context)
        {
        }        public async Task<Company> GetByIdWithDetailsAsync(Guid id)
        {
            var company = await _dbSet
                .Include(c => c.CompanyOwner)
                .Include(c => c.Employees)
                .FirstOrDefaultAsync(c => c.Id == id);
                
            if (company == null)
                throw new KeyNotFoundException($"Company with ID {id} not found");
                
            return company;
        }        public async Task<Company> GetByCVRAsync(string cvr)
        {
            if (string.IsNullOrWhiteSpace(cvr))
                throw new ArgumentException("CVR cannot be empty", nameof(cvr));
                
            var company = await _dbSet
                .FirstOrDefaultAsync(c => c.CVR == cvr);
                
            if (company == null)
                throw new KeyNotFoundException($"Company with CVR {cvr} not found");
                
            return company;
        }

        public async Task<IEnumerable<Company>> GetCompaniesByOwnerIdAsync(Guid ownerId)
        {
            return await _dbSet
                .Include(c => c.Employees)
                .Where(c => c.CompanyOwnerId == ownerId)
                .ToListAsync();
        }        public async Task<bool> ExistsByCVRAsync(string cvr)
        {
            if (string.IsNullOrWhiteSpace(cvr))
                throw new ArgumentException("CVR cannot be empty", nameof(cvr));
                
            return await _dbSet
                .AnyAsync(c => c.CVR == cvr);
        }
    }
}
