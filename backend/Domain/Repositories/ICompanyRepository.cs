using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.Repositories
{
    public interface ICompanyRepository : IRepository<Company>
    {
        Task<Company> GetByIdWithDetailsAsync(Guid id);
        Task<Company> GetByCVRAsync(string cvr);
        Task<IEnumerable<Company>> GetCompaniesByOwnerIdAsync(Guid ownerId);
        Task<bool> ExistsByCVRAsync(string cvr);
    }
}
