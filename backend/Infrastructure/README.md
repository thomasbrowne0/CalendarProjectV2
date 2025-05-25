# Infrastructure Layer

## Overview

The Infrastructure Layer represents the **outermost layer** in our Clean Architecture (Onion Architecture) implementation. It provides concrete implementations of interfaces defined in the inner layers and handles all external concerns like database access, external APIs, file systems, and third-party services.

## Architecture Principles

This layer adheres to Clean Architecture by:
- **Implementing Abstractions**: Provides concrete implementations of Domain and Application interfaces
- **External Dependency Management**: Encapsulates all external framework dependencies
- **Persistence Ignorance**: Domain layer remains unaware of database technology
- **Testability**: Allows easy mocking and testing of business logic

## Key Components

### Data Access Layer
- **AppDbContext**: Entity Framework Core context with PostgreSQL integration
- **Entity Configurations**: Fluent API configurations for all domain entities
- **Repository Pattern**: Concrete implementations of domain repository interfaces
- **Unit of Work**: Transaction management and change tracking coordination

### Database Features
- **Entity Framework Core**: ORM with code-first migrations
- **PostgreSQL**: Production database with optimized indexing
- **Audit Fields**: Automatic tracking of entity creation and modification
- **Soft Deletes**: Data preservation with logical deletion patterns

### Repository Implementations

#### Core Repositories
- **UserRepository**: Base user operations with email-based lookup
- **CompanyOwnerRepository**: Company owner management with owned company navigation
- **CompanyRepository**: Company CRUD with CVR validation and uniqueness checks
- **EmployeeRepository**: Employee management within company boundaries
- **CalendarEventRepository**: Event operations with complex date range queries and participant management

#### Advanced Querying
- **Date Range Filtering**: Complex overlapping event detection algorithms
- **Eager Loading**: Optimized entity relationship loading strategies
- **Performance Optimization**: Strategic indexing for frequent query patterns

### Real-time Communication
- **WebSocketService**: Fleck-based WebSocket server implementation
- **Connection Management**: Client connection lifecycle and authentication
- **Message Broadcasting**: Company-scoped real-time notifications
- **Authentication Integration**: JWT token validation for WebSocket connections

### External Service Integration
- **Dependency Injection**: Service registration and configuration management
- **Configuration Management**: Environment-specific settings and connection strings
- **Service Lifetime Management**: Singleton, Scoped, and Transient service configurations

## Database Architecture

### Entity Relationships
```
User (Abstract)
├── CompanyOwner
│   └── Companies (1:N)
│       └── Employees (1:N)
│           └── CalendarEvents (N:N via Participants)
└── Employee
    ├── Company (N:1)
    └── Events (N:N via Participants)
```

### Key Database Features
- **Table Per Hierarchy**: User inheritance strategy for CompanyOwner/Employee
- **Unique Constraints**: CVR uniqueness for companies, email uniqueness for users
- **Foreign Key Relationships**: Proper cascading and referential integrity
- **Indexing Strategy**: Performance-optimized indexes on frequently queried fields

## WebSocket Implementation

### Real-time Architecture
- **Independent Server**: Runs on separate port (8181) from main API
- **JWT Authentication**: Secure connection establishment with token validation
- **Company Isolation**: Messages are scoped to company boundaries for security
- **Connection Pooling**: Efficient management of concurrent client connections

### Message Types
- **Calendar Events**: `event_created`, `event_updated`, `event_deleted`
- **Employee Management**: `employee_added`, `employee_updated`, `employee_removed`
- **Company Updates**: `company_updated`, `company_deleted`
- **System Messages**: Connection status, errors, acknowledgments

### Security Features
- **Token Validation**: All WebSocket connections must provide valid JWT tokens
- **Company Scoping**: Users only receive messages relevant to their company
- **Connection Tracking**: Proper cleanup of disconnected clients
- **Error Handling**: Graceful handling of connection failures and invalid tokens

## Database Setup & Migrations

### Initial Setup
```powershell
# Create initial migration
dotnet ef migrations add InitialCreate -p Infrastructure -s API

# Update database
dotnet ef database update -p Infrastructure -s API
```

### Migration Management
```powershell
# Add new migration
dotnet ef migrations add YourMigrationName -p Infrastructure -s API

# Update to specific migration
dotnet ef database update YourMigrationName -p Infrastructure -s API

# Remove last migration
dotnet ef migrations remove -p Infrastructure -s API
```

## Configuration

### Database Configuration
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=CalendarDB;Username=your_user;Password=your_password"
  }
}
```

### WebSocket Configuration
```json
{
  "WebSockets": {
    "Host": "0.0.0.0",
    "Port": "8181",
    "SecureConnection": "false",
    "CertificatePath": null,
    "CertificatePassword": null
  }
}
```

## Performance Optimizations

### Database Optimizations
- **Strategic Indexing**: Indexes on frequently queried fields (Email, CVR, CompanyId)
- **Lazy Loading**: Disabled for better performance control
- **Query Optimization**: Explicit Include statements for related entities
- **Connection Pooling**: Efficient database connection management

### Caching Strategies
- **Repository Pattern**: Enables easy addition of caching layers
- **Entity Tracking**: Optimized change detection for updates
- **Bulk Operations**: Support for efficient batch processing

## Dependencies

### Core Dependencies
- **Entity Framework Core**: ORM and database abstraction
- **Npgsql**: PostgreSQL provider for Entity Framework
- **Fleck**: WebSocket server implementation
- **Microsoft.Extensions.Options**: Configuration binding support

### Development Dependencies
- **Entity Framework Tools**: Migration and scaffolding support
- **Microsoft.Extensions.Logging**: Comprehensive logging integration

## Testing Support

### Test Infrastructure
- **In-Memory Database**: SQLite provider for unit testing
- **Repository Mocking**: Interface-based testing strategies
- **Integration Testing**: Real database testing capabilities
- **WebSocket Testing**: Mock connection testing support

### Test Database Setup
```csharp
services.AddDbContext<AppDbContext>(options =>
    options.UseInMemoryDatabase("TestDatabase"));
```
