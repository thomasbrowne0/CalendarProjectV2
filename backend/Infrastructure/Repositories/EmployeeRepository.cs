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
    public class EmployeeRepository : Repository<Employee>, IEmployeeRepository
    {
        public EmployeeRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<IEnumerable<Employee>> GetEmployeesByCompanyIdAsync(Guid companyId)
        {
            return await _dbSet
                .Include(e => e.Company)
                .Where(e => e.CompanyId == companyId)
                .ToListAsync();
        }        public async Task<Employee> GetByEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
                
            var employee = await _dbSet
                .FirstOrDefaultAsync(e => e.Email.ToLower() == email.ToLower());
                
            if (employee == null)
                throw new KeyNotFoundException($"Employee with email {email} not found");
                
            return employee;
        }        public async Task<bool> ExistsByEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
    
            return await _dbSet.AnyAsync(e => e.Email.ToLower() == email.ToLower());
        }
    }
}
