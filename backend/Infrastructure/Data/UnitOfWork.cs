using System;
using System.Threading.Tasks;
using Domain.Repositories;
using Domain.Services;
using Infrastructure.Repositories;

namespace Infrastructure.Data
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly AppDbContext _context;
        private ICompanyRepository? _companyRepository;
        private IUserRepository? _userRepository;
        private ICompanyOwnerRepository? _companyOwnerRepository;
        private IEmployeeRepository? _employeeRepository;
        private ICalendarEventRepository? _calendarEventRepository;

        public UnitOfWork(AppDbContext context)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
        }

        public ICompanyRepository Companies => 
            _companyRepository ??= new CompanyRepository(_context);

        public IUserRepository Users => 
            _userRepository ??= new UserRepository(_context);

        public ICompanyOwnerRepository CompanyOwners => 
            _companyOwnerRepository ??= new CompanyOwnerRepository(_context);

        public IEmployeeRepository Employees => 
            _employeeRepository ??= new EmployeeRepository(_context);

        public ICalendarEventRepository CalendarEvents => 
            _calendarEventRepository ??= new CalendarEventRepository(_context);

        public async Task<int> SaveChangesAsync()
        {
            return await _context.SaveChangesAsync();
        }

        public void Dispose()
        {
            _context.Dispose();
            GC.SuppressFinalize(this);
        }
    }
}
