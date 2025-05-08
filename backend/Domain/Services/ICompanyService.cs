using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.Services
{
    public interface ICompanyService
    {
        Task<Company> CreateCompanyAsync(string name, string cvr, Guid ownerId);
        
        Task<Company> UpdateCompanyAsync(Guid companyId, string name, string cvr);
        
        Task<Employee> AddEmployeeToCompanyAsync(Guid companyId, string firstName, 
            string lastName, string email, string password, string jobTitle);
            
        Task<IEnumerable<Employee>> GetCompanyEmployeesAsync(Guid companyId);
        
        Task<IEnumerable<Company>> GetCompaniesByOwnerIdAsync(Guid ownerId);
        
        Task<bool> VerifyCompanyOwnershipAsync(Guid companyId, Guid ownerId);
    }
}
