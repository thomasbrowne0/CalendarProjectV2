using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.Repositories
{
    public interface IEmployeeRepository : IRepository<Employee>
    {
        Task<IEnumerable<Employee>> GetEmployeesByCompanyIdAsync(Guid companyId);
        Task<Employee> GetByEmailAsync(string email);
    }
}
