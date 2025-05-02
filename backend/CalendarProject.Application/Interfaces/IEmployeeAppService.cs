using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CalendarProject.Application.DTOs;

namespace CalendarProject.Application.Interfaces
{
    public interface IEmployeeAppService
    {
        Task<EmployeeDto> GetEmployeeByIdAsync(Guid id);
        Task<IEnumerable<EmployeeDto>> GetEmployeesByCompanyIdAsync(Guid companyId);
        Task<EmployeeDto> CreateEmployeeAsync(Guid companyId, EmployeeCreateDto employeeDto);
        Task<EmployeeDto> UpdateEmployeeAsync(Guid id, EmployeeUpdateDto employeeDto);
        Task<bool> DeleteEmployeeAsync(Guid id);
        Task<bool> ValidateEmployeeCompanyMembershipAsync(Guid employeeId, Guid companyId);
    }
}
