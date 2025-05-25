# API Layer

## Overview

The API layer serves as the entry point for our Calendar Project V2, implementing Clean Architecture (Onion Architecture) principles. It exposes RESTful endpoints for our Flutter frontend and provides real-time WebSocket communication for instant updates.

## Architecture

This layer follows the **Presentation Layer** pattern in Clean Architecture, handling:
- HTTP request/response handling
- Input validation and model binding
- Authentication and authorization
- WebSocket connection management
- Cross-cutting concerns (CORS, logging, error handling)

## Key Components

### Controllers

- **AuthController**: Handles user authentication and company owner registration
- **CompanyController**: Manages company CRUD operations with ownership validation
- **EmployeeController**: Handles employee management within company boundaries
- **CalendarController**: Manages calendar events with real-time notifications

### Configuration

- **Program.cs**: Application entry point with service configuration
- **Startup.cs**: Core service registration and middleware pipeline
- **Proxy/**: Configuration management for external services

### Real-time Features

The API includes WebSocket support using Fleck for instant updates:
- Calendar event creation/updates/deletion
- Employee additions/removals
- Company changes
- Cross-company isolation for security

## API Endpoints

### Authentication
- `POST /api/auth/login` - User authentication with JWT token generation
- `POST /api/auth/register-company-owner` - Company owner registration

### Companies
- `GET /api/companies` - Get all companies owned by authenticated user
- `GET /api/companies/{id}` - Get specific company details
- `POST /api/companies` - Create new company (CVR validation included)
- `PUT /api/companies/{id}` - Update company information
- `DELETE /api/companies/{id}` - Delete company and all related data

### Employees
- `GET /api/companies/{companyId}/employees` - Get all company employees
- `GET /api/companies/{companyId}/employees/{id}` - Get specific employee
- `POST /api/companies/{companyId}/employees` - Create new employee
- `PUT /api/companies/{companyId}/employees/{id}` - Update employee information
- `DELETE /api/companies/{companyId}/employees/{id}` - Remove employee

### Calendar Events
- `GET /api/companies/{companyId}/events` - Get all company events with date filtering
- `GET /api/companies/{companyId}/events/employee/{employeeId}` - Get employee-specific events
- `GET /api/companies/{companyId}/events/{id}` - Get detailed event information
- `POST /api/companies/{companyId}/events` - Create new calendar event
- `PUT /api/companies/{companyId}/events/{id}` - Update existing event
- `DELETE /api/companies/{companyId}/events/{id}` - Delete calendar event
- `POST /api/companies/{companyId}/events/{id}/participants/{employeeId}` - Add event participant
- `DELETE /api/companies/{companyId}/events/{id}/participants/{employeeId}` - Remove event participant

## Security Features

### Authentication & Authorization
- JWT-based authentication with configurable expiration
- Role-based access control (Company Owner vs Employee)
- Company-scoped data access (users can only access their company's data)
- Secure password hashing using BCrypt

### Data Protection
- CORS configuration for frontend integration
- Input validation on all endpoints
- SQL injection prevention through Entity Framework
- XSS protection via proper model binding

## WebSocket Connection

Connect to `/ws?token=YOUR_JWT_TOKEN` to establish real-time communication:

```javascript
const ws = new WebSocket('ws://localhost:8181/ws?token=YOUR_JWT_TOKEN');

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    // Handle real-time updates based on data.type
    // Types: 'event_created', 'event_updated', 'event_deleted', 'employee_added', etc.
};
```

## Error Handling

The API implements comprehensive error handling:
- Standardized error responses with meaningful messages
- Proper HTTP status codes
- Validation error details for client-side feedback
- Logging for debugging and monitoring

## Configuration

Key configuration settings in `appsettings.json`:
- Database connection strings
- JWT authentication settings
- WebSocket server configuration
- CORS allowed origins
- Logging levels

## Dependencies

- ASP.NET Core 8.0
- Entity Framework Core (PostgreSQL)
- JWT Authentication
- BCrypt for password hashing
- Fleck for WebSocket support
- AutoMapper for DTO mapping
