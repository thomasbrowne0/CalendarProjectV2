using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Application.DTOs;
using Application.Interfaces;
using Domain.Entities;
using Domain.IRepositories;
using Domain.IServices;

namespace Application.Services
{
    public class EmployeeAppService : IEmployeeAppService
    {
        private readonly IEmployeeRepository _employeeRepository;
        private readonly ICompanyRepository _companyRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IWebSocketService _webSocketService;

        public EmployeeAppService(
            IEmployeeRepository employeeRepository,
            ICompanyRepository companyRepository,
            IUnitOfWork unitOfWork,
            IWebSocketService webSocketService)
        {
            _employeeRepository = employeeRepository ?? throw new ArgumentNullException(nameof(employeeRepository));
            _companyRepository = companyRepository ?? throw new ArgumentNullException(nameof(companyRepository));
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
            _webSocketService = webSocketService ?? throw new ArgumentNullException(nameof(webSocketService));
        }

        public async Task<EmployeeDto> GetEmployeeByIdAsync(Guid id)
        {
            var employee = await _employeeRepository.GetByIdAsync(id);
            if (employee == null)
                throw new Exception($"Employee with ID {id} not found");

            return MapToEmployeeDto(employee);
        }

        public async Task<IEnumerable<EmployeeDto>> GetEmployeesByCompanyIdAsync(Guid companyId)
        {
            var employees = await _employeeRepository.GetEmployeesByCompanyIdAsync(companyId);
            return employees.Select(MapToEmployeeDto);
        }

        public async Task<EmployeeDto> CreateEmployeeAsync(Guid companyId, EmployeeCreateDto employeeCreateDto)
        {
            var company = await _companyRepository.GetByIdAsync(companyId);
            if (company == null)
                throw new Exception($"Company with ID {companyId} not found");
            
            var exists = await _employeeRepository.ExistsByEmailAsync(employeeCreateDto.Email);            if (exists)
                throw new Exception($"Employee with email {employeeCreateDto.Email} already exists");

            /* We need to implement proper password hashing */
            var employee = new Employee(
                employeeCreateDto.FirstName,
                employeeCreateDto.LastName,
                employeeCreateDto.Email,
                employeeCreateDto.Password,
                companyId,
                employeeCreateDto.JobTitle,
                employeeCreateDto.MobilePhone
            );            await _employeeRepository.AddAsync(employee);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyEmployeeAddedAsync(companyId, employee.Id);

            return MapToEmployeeDto(employee);
        }

        public async Task<EmployeeDto> UpdateEmployeeAsync(Guid id, EmployeeUpdateDto employeeUpdateDto)
        {
            var employee = await _employeeRepository.GetByIdAsync(id);
            if (employee == null)
                throw new Exception($"Employee with ID {id} not found");

            employee.UpdateDetails(
                employeeUpdateDto.FirstName,
                employeeUpdateDto.LastName,
                employeeUpdateDto.Email
            );            employee.UpdateJobTitle(employeeUpdateDto.JobTitle);
            employee.UpdateMobilePhone(employeeUpdateDto.MobilePhone);

            await _employeeRepository.UpdateAsync(employee);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyCompanyDataChangedAsync(
                employee.CompanyId, 
                "EmployeeUpdated", 
                MapToEmployeeDto(employee));

            return MapToEmployeeDto(employee);
        }

        public async Task<bool> DeleteEmployeeAsync(Guid id)
        {
            var employee = await _employeeRepository.GetByIdAsync(id);
            if (employee == null)
                return false;

            var companyId = employee.CompanyId;            await _employeeRepository.DeleteAsync(employee);
            await _unitOfWork.SaveChangesAsync();

            await _webSocketService.NotifyEmployeeRemovedAsync(companyId, id);

            return true;
        }

        public async Task<bool> ValidateEmployeeCompanyMembershipAsync(Guid employeeId, Guid companyId)
        {
            var employee = await _employeeRepository.GetByIdAsync(employeeId);
            if (employee == null)
                return false;

            return employee.CompanyId == companyId;
        }

        private EmployeeDto MapToEmployeeDto(Employee employee)
        {
            return new EmployeeDto
            {
                Id = employee.Id,
                FirstName = employee.FirstName,
                LastName = employee.LastName,
                Email = employee.Email,
                JobTitle = employee.JobTitle,
                CompanyId = employee.CompanyId,                CompanyName = employee.Company?.Name ?? string.Empty,
                MobilePhone = employee.MobilePhone
            };
        }
    }
}
