using System;

namespace Domain.Entities
{
    public abstract class User
    {
        public Guid Id { get; protected set; }
        public string FirstName { get; protected set; }
        public string LastName { get; protected set; }
        public string Email { get; protected set; }
        public string PasswordHash { get; protected set; }        protected User() { }

        protected User(string firstName, string lastName, string email, string passwordHash)
        {
            if (string.IsNullOrWhiteSpace(firstName))
                throw new ArgumentException("First name cannot be empty", nameof(firstName));
            
            if (string.IsNullOrWhiteSpace(lastName))
                throw new ArgumentException("Last name cannot be empty", nameof(lastName));
            
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("Email cannot be empty", nameof(email));
            
            if (string.IsNullOrWhiteSpace(passwordHash))
                throw new ArgumentException("Password hash cannot be empty", nameof(passwordHash));

            Id = Guid.NewGuid();
            FirstName = firstName;
            LastName = lastName;
            Email = email;
            PasswordHash = passwordHash;
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

        public void UpdatePassword(string passwordHash)
        {
            if (string.IsNullOrWhiteSpace(passwordHash))
                throw new ArgumentException("Password hash cannot be empty", nameof(passwordHash));
            
            PasswordHash = passwordHash;
        }
    }
}
