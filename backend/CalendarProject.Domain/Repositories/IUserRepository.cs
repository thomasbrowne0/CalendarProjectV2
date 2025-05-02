using System;
using System.Threading.Tasks;
using CalendarProject.Domain.Entities;

namespace CalendarProject.Domain.Repositories
{
    public interface IUserRepository : IRepository<User>
    {
        Task<User> GetByEmailAsync(string email);
        Task<bool> ExistsByEmailAsync(string email);
    }
}
