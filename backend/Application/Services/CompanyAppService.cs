using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Application.DTOs;
using Application.Interfaces;
using Domain.Entities;
using Domain.Repositories;
using Domain.Services;

namespace Application.Services
{
    public class CompanyAppService : ICompanyAppService
    {
        private readonly ICompanyRepository _companyRepository;
        private readonly ICompanyOwnerRepository _companyOwnerRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IWebSocketService _webSocketService;

        public CompanyAppService(
            ICompanyRepository companyRepository,
            ICompanyOwnerRepository companyOwnerRepository,
            IUnitOfWork unitOfWork,
            IWebSocketService webSocketService)
        {
            _companyRepository = companyRepository ?? throw new ArgumentNullException(nameof(companyRepository));
            _companyOwnerRepository = companyOwnerRepository ?? throw new ArgumentNullException(nameof(companyOwnerRepository));
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
            _webSocketService = webSocketService ?? throw new ArgumentNullException(nameof(webSocketService));
        }

        public async Task<CompanyDto> GetCompanyByIdAsync(Guid id)
        {
            var company = await _companyRepository.GetByIdWithDetailsAsync(id);
            if (company == null)
                throw new Exception($"Company with ID {id} not found");

            return MapToCompanyDto(company);
        }

        public async Task<IEnumerable<CompanyDto>> GetCompaniesByOwnerIdAsync(Guid ownerId)
        {
            var companies = await _companyRepository.GetCompaniesByOwnerIdAsync(ownerId);
            return companies.Select(MapToCompanyDto);
        }

        public async Task<CompanyDto> CreateCompanyAsync(Guid ownerId, CompanyCreateDto companyDto)
        {
            var owner = await _companyOwnerRepository.GetByIdAsync(ownerId);
            if (owner == null)
                throw new Exception($"Company owner with ID {ownerId} not found");

            var existingCompany = await _companyRepository.GetByCVRAsync(companyDto.CVR);
            if (existingCompany != null)
                throw new Exception($"A company with CVR {companyDto.CVR} already exists");

            var company = new Company(companyDto.Name, companyDto.CVR, ownerId);

            await _companyRepository.AddAsync(company);
            await _unitOfWork.SaveChangesAsync();

            return MapToCompanyDto(company);
        }

        public async Task<CompanyDto> UpdateCompanyAsync(Guid id, CompanyUpdateDto companyDto)
        {
            var company = await _companyRepository.GetByIdAsync(id);
            if (company == null)
                throw new Exception($"Company with ID {id} not found");

            company.UpdateDetails(companyDto.Name, companyDto.CVR);

            await _companyRepository.UpdateAsync(company);
            await _unitOfWork.SaveChangesAsync();

            // Notify connected clients about company update
            await _webSocketService.NotifyCompanyDataChangedAsync(company.Id, "CompanyUpdated", MapToCompanyDto(company));

            return MapToCompanyDto(company);
        }

        public async Task<bool> DeleteCompanyAsync(Guid id)
        {
            var company = await _companyRepository.GetByIdAsync(id);
            if (company == null)
                return false;

            await _companyRepository.DeleteAsync(company);
            await _unitOfWork.SaveChangesAsync();

            return true;
        }

        public async Task<bool> ValidateCompanyOwnershipAsync(Guid companyId, Guid ownerId)
        {
            var company = await _companyRepository.GetByIdAsync(companyId);
            if (company == null)
                return false;

            return company.CompanyOwnerId == ownerId;
        }

        private CompanyDto MapToCompanyDto(Company company)
        {
            return new CompanyDto
            {
                Id = company.Id,
                Name = company.Name,
                CVR = company.CVR,
                CompanyOwnerId = company.CompanyOwnerId,
                OwnerName = company.CompanyOwner?.FirstName + " " + company.CompanyOwner?.LastName,
                EmployeeCount = company.Employees?.Count ?? 0
            };
        }
    }
}
