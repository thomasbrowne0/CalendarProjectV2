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
                
            // Add discriminator for the inheritance
            builder.HasDiscriminator<string>("UserType")
                .HasValue<CompanyOwner>("CompanyOwner")
                .HasValue<Employee>("Employee");
                
            // Create index on email to improve query performance
            builder.HasIndex(u => u.Email)
                .IsUnique();
        }
    }
}
