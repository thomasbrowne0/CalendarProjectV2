using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using Infrastructure;

namespace API
{
    public class Startup
    {
        public IConfiguration Configuration { get; }

        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public void ConfigureServices(IServiceCollection services)
        {
            // Add infrastructure services
            services.AddInfrastructure(Configuration);

            // CORS configuration
            services.AddCors(options =>
            {
                options.AddPolicy("AllowFlutterApp", builder =>
                {
                    builder.WithOrigins("http://localhost:3000") // Update with your Flutter web app URL
                        .AllowAnyMethod()
                        .AllowAnyHeader()
                        .AllowCredentials();
                });
                options.AddPolicy("AllowAll", builder =>
                {
                    builder.AllowAnyOrigin()
                           .AllowAnyMethod()
                           .AllowAnyHeader();
                });
            });

            // Add controllers
            services.AddControllers();

            // Swagger/OpenAPI
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "Calendar Project API", Version = "v1" });
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Calendar Project API v1"));
            }
            else
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            
            // Apply CORS policy before routing
            app.UseCors("AllowAll");
            
            app.UseRouting();
            
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
            
            // Force instantiation of WebSocketService to start Fleck server
            var webSocketService = app.ApplicationServices.GetRequiredService<Application.Interfaces.IWebSocketService>();
        }
    }
}