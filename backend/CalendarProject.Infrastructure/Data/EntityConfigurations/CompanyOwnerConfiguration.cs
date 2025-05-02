using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using CalendarProject.Domain.Entities;

namespace CalendarProject.Infrastructure.Data.EntityConfigurations
{
    public class CompanyOwnerConfiguration : IEntityTypeConfiguration<CompanyOwner>
    {
        public void Configure(EntityTypeBuilder<CompanyOwner> builder)
        {
            // Configure navigation properties
            builder.HasMany(o => o.OwnedCompanies)
                .WithOne(c => c.CompanyOwner)
                .HasForeignKey(c => c.CompanyOwnerId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
