using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CalendarProject.Domain.Entities;

namespace CalendarProject.Domain.Repositories
{
    public interface IEmployeeRepository : IRepository<Employee>
    {
        Task<IEnumerable<Employee>> GetEmployeesByCompanyIdAsync(Guid companyId);
        Task<Employee> GetByEmailAsync(string email);
    }
}
