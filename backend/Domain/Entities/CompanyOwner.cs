using System;
using System.Collections.Generic;

namespace Domain.Entities;

public class CompanyOwner : User
{
    public virtual ICollection<Company> OwnedCompanies { get; private set; }

    private CompanyOwner() : base()
    {
    }

    public CompanyOwner(string firstName, string lastName, string email, string passwordHash)
        : base(firstName, lastName, email, passwordHash)
    {
        OwnedCompanies = new List<Company>();
    }

    public Company CreateCompany(string name, string cvr)
    {
        var company = new Company(name, cvr, Id);
        return company;
    }
}