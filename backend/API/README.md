# API Layer

## Overview

The API layer is the entry point of our application, exposing RESTful endpoints that can be consumed by our Flutter frontend. It also handles WebSocket connections for real-time updates.

## Key Components

### Controllers

- **AuthController**: Handles user authentication and registration
- **CompanyController**: Manages company resources
- **EmployeeController**: Handles employee management
- **CalendarController**: Manages calendar events

### WebSocket Support

The API includes WebSocket support for real-time updates:

- New calendar events
- Event updates
- Employee additions/removals
- Company changes

## API Endpoints

### Authentication
- POST `/api/auth/login` - Login with email and password
- POST `/api/auth/register-company-owner` - Register a new company owner

### Companies
- GET `/api/companies` - Get all companies owned by the current user
- GET `/api/companies/{id}` - Get a specific company
- POST `/api/companies` - Create a new company
- PUT `/api/companies/{id}` - Update a company
- DELETE `/api/companies/{id}` - Delete a company

### Employees
- GET `/api/companies/{companyId}/employees` - Get all employees for a company
- GET `/api/companies/{companyId}/employees/{id}` - Get a specific employee
- POST `/api/companies/{companyId}/employees` - Create a new employee
- PUT `/api/companies/{companyId}/employees/{id}` - Update an employee
- DELETE `/api/companies/{companyId}/employees/{id}` - Delete an employee

### Calendar Events
- GET `/api/companies/{companyId}/events` - Get all events for a company
- GET `/api/companies/{companyId}/events/employee/{employeeId}` - Get events for a specific employee
- GET `/api/companies/{companyId}/events/{id}` - Get a specific event
- POST `/api/companies/{companyId}/events` - Create a new event
- PUT `/api/companies/{companyId}/events/{id}` - Update an event
- DELETE `/api/companies/{companyId}/events/{id}` - Delete an event
- POST `/api/companies/{companyId}/events/{id}/participants/{employeeId}` - Add a participant to an event
- DELETE `/api/companies/{companyId}/events/{id}/participants/{employeeId}` - Remove a participant from an event

## Authentication

All authenticated endpoints require a `session-id` header obtained from the login or registration endpoints.

## WebSocket Connection

Connect to `/ws` and send a session message to establish a WebSocket connection for real-time updates:
```json
{
  "type": "session",
  "sessionId": "YOUR_SESSION_ID"
}
```
