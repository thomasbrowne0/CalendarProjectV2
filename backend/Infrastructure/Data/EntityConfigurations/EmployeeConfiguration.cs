using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Domain.Entities;

namespace Infrastructure.Data.EntityConfigurations;

public class EmployeeConfiguration : IEntityTypeConfiguration<Employee>
{
    public void Configure(EntityTypeBuilder<Employee> builder)
    {
        builder.Property(e => e.JobTitle)
            .IsRequired()
            .HasMaxLength(100);
        builder.Property(e => e.MobilePhone)
            .HasMaxLength(30);

        builder.HasOne(e => e.Company)
            .WithMany(c => c.Employees)
            .HasForeignKey(e => e.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(e => e.Events)
            .WithMany(e => e.Participants)
            .UsingEntity(j => j.ToTable("EmployeeEvents"));
    }
}