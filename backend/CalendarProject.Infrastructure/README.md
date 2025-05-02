# Infrastructure Layer

## What is the Infrastructure Layer?

The Infrastructure layer is the outer layer of our Onion Architecture. It provides concrete implementations of interfaces defined in the inner layers (Domain and Application). This layer deals with database access, external APIs, file systems, and other external concerns.

## Key Components

1. **Data Access**
   - Entity Framework Core DbContext
   - Entity Configurations
   - Repository Implementations
   - Unit of Work Implementation

2. **External Services**
   - WebSocket Implementation
   - Authentication/Authorization Infrastructure

## Database Setup

The infrastructure layer uses Entity Framework Core with SQL Server. To set up the database:

1. Make sure you have the connection string in your `appsettings.json`
2. Run migrations:
   ```
   dotnet ef migrations add InitialCreate -p CalendarProject.Infrastructure -s CalendarProject.API
   dotnet ef database update -p CalendarProject.Infrastructure -s CalendarProject.API
   ```

## WebSocket Implementation

The Infrastructure layer contains a WebSocket implementation that:
- Manages client connections
- Routes messages to appropriate users based on company membership
- Provides real-time updates for calendar events and employee changes

## Dependency Injection

The Infrastructure layer registers all its dependencies in the `DependencyInjection.cs` file, making it easy to set up in the API layer's startup.
