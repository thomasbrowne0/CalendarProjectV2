using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CalendarProject.Domain.Entities;

namespace CalendarProject.Domain.Repositories
{
    public interface ICompanyOwnerRepository : IRepository<CompanyOwner>
    {
        Task<CompanyOwner> GetByIdWithCompaniesAsync(Guid id);
        Task<CompanyOwner> GetByEmailAsync(string email);
    }
}
