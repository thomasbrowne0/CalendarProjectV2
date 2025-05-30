using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Application.DTOs;

namespace Application.Interfaces;

public interface ICompanyAppService
{
    Task<CompanyDto> GetCompanyByIdAsync(Guid id);
    Task<IEnumerable<CompanyDto>> GetCompaniesByOwnerIdAsync(Guid ownerId);
    Task<CompanyDto> CreateCompanyAsync(Guid ownerId, CompanyCreateDto companyDto);
    Task<CompanyDto> UpdateCompanyAsync(Guid id, CompanyUpdateDto companyDto);
    Task<bool> DeleteCompanyAsync(Guid id);
    Task<bool> ValidateCompanyOwnershipAsync(Guid companyId, Guid ownerId);
}