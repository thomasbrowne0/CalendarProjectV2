using System;
using System.Collections.Generic;

namespace Application.DTOs
{
    public class CompanyDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string CVR { get; set; } = string.Empty;
        public Guid CompanyOwnerId { get; set; }
        public string OwnerName { get; set; } = string.Empty;
        public int EmployeeCount { get; set; }
    }

    public class CompanyCreateDto
    {
        public string Name { get; set; } = string.Empty;
        public string CVR { get; set; } = string.Empty;
    }

    public class CompanyUpdateDto
    {
        public string Name { get; set; } = string.Empty;
        public string CVR { get; set; } = string.Empty;
    }
}
