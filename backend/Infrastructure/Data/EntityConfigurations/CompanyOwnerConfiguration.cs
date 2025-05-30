using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Domain.Entities;

namespace Infrastructure.Data.EntityConfigurations;

public class CompanyOwnerConfiguration : IEntityTypeConfiguration<CompanyOwner>
{
    public void Configure(EntityTypeBuilder<CompanyOwner> builder)
    {
        builder.HasMany(o => o.OwnedCompanies)
            .WithOne(c => c.CompanyOwner)
            .HasForeignKey(c => c.CompanyOwnerId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}