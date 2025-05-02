using System;
using System.Threading.Tasks;
using CalendarProject.Domain.Repositories;

namespace CalendarProject.Domain.Services
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
