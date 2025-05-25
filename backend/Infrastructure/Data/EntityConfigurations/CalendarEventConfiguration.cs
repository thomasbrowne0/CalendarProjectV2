using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Domain.Entities;

namespace Infrastructure.Data.EntityConfigurations
{
    public class CalendarEventConfiguration : IEntityTypeConfiguration<CalendarEvent>
    {
        public void Configure(EntityTypeBuilder<CalendarEvent> builder)
        {
            builder.ToTable("CalendarEvents");

            builder.HasKey(e => e.Id);
            
            builder.Property(e => e.Title)
                .IsRequired()
                .HasMaxLength(100);
                
            builder.Property(e => e.Description)
                .HasMaxLength(500);
                
            builder.Property(e => e.StartTime)
                .IsRequired();
                  builder.Property(e => e.EndTime)
                .IsRequired();

            builder.HasOne(e => e.CreatedBy)
                .WithMany()
                .HasForeignKey(e => e.CreatedById)
                .OnDelete(DeleteBehavior.Restrict);
                
            builder.HasOne(e => e.Company)
                .WithMany()
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
                
            builder.HasMany(e => e.Participants)
                .WithMany(e => e.Events)
                .UsingEntity(j => j.ToTable("EmployeeEvents"));

            /* We need these indexes because calendar queries frequently filter by
               company and date ranges for performance optimization */
            builder.HasIndex(e => e.CompanyId);
            builder.HasIndex(e => e.StartTime);
            builder.HasIndex(e => e.EndTime);
        }
    }
}
