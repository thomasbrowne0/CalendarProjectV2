using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Domain.Entities;

namespace Infrastructure.Data.EntityConfigurations;

public class CompanyConfiguration : IEntityTypeConfiguration<Company>
{
    public void Configure(EntityTypeBuilder<Company> builder)
    {
        builder.ToTable("Companies");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.Name)
            .IsRequired()
            .HasMaxLength(100);
        builder.Property(c => c.CVR)
            .IsRequired()
            .HasMaxLength(20);

        /* We need a unique index on CVR because it's the legal business identifier
           and must be unique across all companies in the system */
        builder.HasIndex(c => c.CVR)
            .IsUnique();

        builder.HasOne(c => c.CompanyOwner)
            .WithMany(o => o.OwnedCompanies)
            .HasForeignKey(c => c.CompanyOwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(c => c.Employees)
            .WithOne(e => e.Company)
            .HasForeignKey(e => e.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}