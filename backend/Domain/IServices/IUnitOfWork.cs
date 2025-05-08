using System;
using System.Threading.Tasks;
using Domain.IRepositories;

namespace Domain.IServices
{
    public interface IUnitOfWork : IDisposable
    {
        ICompanyRepository Companies { get; }
        IUserRepository Users { get; }
        ICompanyOwnerRepository CompanyOwners { get; }
        IEmployeeRepository Employees { get; }
        ICalendarEventRepository CalendarEvents { get; }

        Task<int> SaveChangesAsync();
    }
}
