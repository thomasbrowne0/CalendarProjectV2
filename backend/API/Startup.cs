using System;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Infrastructure;
using Application.Interfaces;

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
            services.AddInfrastructure(Configuration);

            services.AddCors(options =>
            {
                options.AddPolicy("AllowFlutterApp", builder =>
                {
                    builder.WithOrigins("https://calendarfrontend-e6233.web.app")
                           .AllowAnyMethod()
                           .AllowAnyHeader()
                           .AllowCredentials();
                });
            });

            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = Configuration["Jwt:Issuer"],
                        ValidAudience = Configuration["Jwt:Audience"],
                        IssuerSigningKey = new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(Configuration["Jwt:Key"] ?? "DefaultSecretKeyForDevelopment123!"))
                    };
                });

            services.AddAuthorization(options =>
            {
                options.AddPolicy("CompanyOwnerOnly", policy =>
                    policy.RequireClaim("UserType", "CompanyOwner"));
            });

            services.AddControllers();

            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "Calendar Project API", Version = "v1" });
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Description = "JWT Authorization header using the Bearer scheme",
                    Name = "Authorization",
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey,
                    Scheme = "Bearer"
                });
                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });
        }        /* We need this specific WebSocket mapping because the frontend expects a /ws endpoint
           and we're proxying to our Fleck WebSocket server for real-time notifications */
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

            app.UseCors("AllowFlutterApp");

            app.UseRouting();

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseWebSockets();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.Map("/ws", async context =>
                {
                    if (context.WebSockets.IsWebSocketRequest)
                    {
                        var fleckUrl = $"ws://{Configuration["WebSockets:Host"]}:{Configuration["WebSockets:Port"]}";
                        var webSocket = await context.WebSockets.AcceptWebSocketAsync();
                        var webSocketService = context.RequestServices.GetRequiredService<IWebSocketService>();
                        await webSocketService.ProxyToFleckAsync(webSocket, fleckUrl);
                    }
                    else
                    {
                        context.Response.StatusCode = 400;
                    }
                });
            });

            var webSocketService = app.ApplicationServices.GetRequiredService<IWebSocketService>();
        }
    }
}