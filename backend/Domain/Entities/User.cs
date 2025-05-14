using System;
using System.Security.Cryptography;
using System.Text;

namespace Domain.Entities
{
    public abstract class User
    {
        public Guid Id { get; protected set; }
        public string FirstName { get; protected set; }
        public string LastName { get; protected set; }
        public string Email { get; protected set; }
        public string PasswordHash { get; protected set; }

        // For EF Core
        protected User() { }

        protected User(string firstName, string lastName, string email, string password)
        {
            if (string.IsNullOrWhiteSpace(firstName))
                throw new ArgumentException("First name cannot be empty", nameof(firstName));
            
            if (string.IsNullOrWhiteSpace(lastName))
                throw new ArgumentException("Last name cannot be empty", nameof(lastName));
            
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
            
            if (string.IsNullOrWhiteSpace(password))
                throw new ArgumentException("Password hash cannot be empty", nameof(password));

            Id = Guid.NewGuid();
            FirstName = firstName;
            LastName = lastName;
            Email = email;
            PasswordHash = HashPassword(password);
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }

        public void UpdateDetails(string firstName, string lastName, string email)
        {
            if (!string.IsNullOrWhiteSpace(firstName))
                FirstName = firstName;
            
            if (!string.IsNullOrWhiteSpace(lastName))
                LastName = lastName;
            
            if (!string.IsNullOrWhiteSpace(email))
                Email = email;
        }

        public void UpdatePassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
                throw new ArgumentException("Password cannot be empty", nameof(password));
            
            PasswordHash = HashPassword(password);
        }
    }
}
