using System;
using System.Threading.Tasks;
using Domain.Entities;

namespace Domain.IRepositories;

public interface IUserRepository : IRepository<User>
{
    Task<User> GetByEmailAsync(string email);
    Task<bool> ExistsByEmailAsync(string email);
}