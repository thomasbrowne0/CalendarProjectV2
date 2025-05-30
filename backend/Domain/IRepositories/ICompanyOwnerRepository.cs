using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.IRepositories;

public interface ICompanyOwnerRepository : IRepository<CompanyOwner>
{
    Task<CompanyOwner> GetByIdWithCompaniesAsync(Guid id);
    Task<CompanyOwner> GetByEmailAsync(string email);
}