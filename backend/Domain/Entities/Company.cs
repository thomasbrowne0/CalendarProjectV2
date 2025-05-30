using System;
using System.Collections.Generic;

namespace Domain.Entities;

public class Company
{
    public Guid Id { get; private set; }
    public string Name { get; private set; }
    public string CVR { get; private set; }
    public Guid CompanyOwnerId { get; private set; }
    public virtual CompanyOwner CompanyOwner { get; private set; }
    public virtual ICollection<Employee> Employees { get; private set; }

    private Company()
    {
    }

    public Company(string name, string cvr, Guid companyOwnerId)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Company name cannot be empty", nameof(name));

        if (string.IsNullOrWhiteSpace(cvr))
            throw new ArgumentException("CVR cannot be empty", nameof(cvr));

        Id = Guid.NewGuid();
        Name = name;
        CVR = cvr;
        CompanyOwnerId = companyOwnerId;
        Employees = new List<Employee>();
    }

    public void UpdateDetails(string name, string cvr)
    {
        if (!string.IsNullOrWhiteSpace(name))
            Name = name;

        if (!string.IsNullOrWhiteSpace(cvr))
            CVR = cvr;
    }
}