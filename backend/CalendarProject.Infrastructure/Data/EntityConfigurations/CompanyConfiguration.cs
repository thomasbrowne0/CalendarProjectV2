using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using CalendarProject.Domain.Entities;

namespace CalendarProject.Infrastructure.Data.EntityConfigurations
{
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
                
            // Create index on CVR to improve query performance and ensure uniqueness
            builder.HasIndex(c => c.CVR)
                .IsUnique();
                
            // Configure navigation properties
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
}
