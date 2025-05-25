using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Domain.Entities;

namespace Infrastructure.Data.EntityConfigurations
{
    public class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            builder.ToTable("Users");
            
            builder.HasKey(u => u.Id);
            
            builder.Property(u => u.FirstName)
                .IsRequired()
                .HasMaxLength(50);
                
            builder.Property(u => u.LastName)
                .IsRequired()
                .HasMaxLength(50);
                
            builder.Property(u => u.Email)
                .IsRequired()
                .HasMaxLength(100);
                  builder.Property(u => u.PasswordHash)
                .IsRequired();

            /* We need discriminator for Table Per Hierarchy inheritance to distinguish
               between CompanyOwner and Employee entities in the same table */
            builder.HasDiscriminator<string>("UserType")
                .HasValue<CompanyOwner>("CompanyOwner")
                .HasValue<Employee>("Employee");

            /* We need unique index on email because it's used for login and
               must be unique across all users in the system */
            builder.HasIndex(u => u.Email)
                .IsUnique();
        }
    }
}
