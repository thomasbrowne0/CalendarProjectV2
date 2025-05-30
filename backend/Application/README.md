# Application Layer

## Overview

The Application Layer serves as the **Use Cases/Services Layer** in our Clean Architecture implementation. It
orchestrates business workflows, enforces business rules, and coordinates between the Domain and Infrastructure layers
without depending on external frameworks.

## Architecture Principles

This layer follows Clean Architecture principles by:

- **Dependency Inversion**: Depends only on Domain abstractions, not concrete implementations
- **Single Responsibility**: Each service handles one specific business domain
- **Business Logic Coordination**: Orchestrates complex workflows using Domain entities
- **Technology Independence**: Contains no framework-specific code

## Core Components

### Application Services

- **AuthService**: Handles user authentication, JWT token generation, and password validation
- **CompanyAppService**: Manages company lifecycle and ownership validation
- **EmployeeAppService**: Coordinates employee management within company boundaries
- **CalendarAppService**: Orchestrates calendar event operations with real-time notifications

### Data Transfer Objects (DTOs)

- **UserDto**: Standardized user data representation for API responses
- **CompanyDto**: Company information transfer object
- **EmployeeDto**: Employee data with company context
- **CalendarEventDto**: Calendar event representation with participant details

### Key Interfaces

- **IAuthService**: Authentication and authorization contract
- **ICompanyAppService**: Company management operations
- **IEmployeeAppService**: Employee lifecycle management
- **ICalendarAppService**: Calendar event orchestration
- **IWebSocketService**: Real-time notification abstraction

## Business Logic & Workflows

### Authentication Flow

1. **User Login**: Validates credentials against hashed passwords using BCrypt
2. **JWT Generation**: Creates secure tokens with company and role claims
3. **Password Security**: Enforces strong password hashing for data protection

### Company Management

1. **Company Creation**: Validates CVR uniqueness and assigns ownership
2. **Access Control**: Ensures owners can only access their own companies
3. **Data Integrity**: Manages cascading operations for company-related entities

### Employee Lifecycle

1. **Employee Registration**: Creates accounts within company boundaries
2. **Permission Validation**: Ensures only company owners can manage employees
3. **Data Consistency**: Maintains referential integrity across employee operations

### Calendar Event Coordination

1. **Event Creation**: Validates time slots and participant availability
2. **UTC Handling**: Converts and stores all dates in UTC for consistency
3. **Real-time Notifications**: Broadcasts changes to relevant WebSocket clients
4. **Participant Management**: Enforces company-scoped participant restrictions

## Security Implementation

### Authorization Patterns

- **Company Ownership Validation**: Ensures users can only access their own company data
- **Role-based Access**: Differentiates between Company Owner and Employee permissions
- **Data Isolation**: Prevents cross-company data leakage

### Data Protection

- **Password Hashing**: Uses BCrypt with proper salt rounds for security
- **JWT Claims**: Includes necessary user context for authorization decisions
- **Input Validation**: Validates all input data before domain operations

## Real-time Communication

### WebSocket Integration

The Application layer coordinates with WebSocket services to provide:

- **Event Notifications**: Instant updates when calendar events are created/modified
- **Employee Updates**: Real-time notifications for employee additions/removals
- **Company Changes**: Live updates for company information modifications
- **Targeted Messaging**: Company-scoped message delivery for data privacy

### Notification Types

- `event_created` - New calendar event notification
- `event_updated` - Calendar event modification
- `event_deleted` - Calendar event removal
- `employee_added` - New employee notification
- `employee_updated` - Employee information changes
- `company_updated` - Company information modifications

## Error Handling & Validation

### Business Rule Enforcement

- **Domain Validation**: Ensures all business rules are followed before persistence
- **Data Consistency**: Validates relationships between entities
- **Authorization Checks**: Prevents unauthorized access to resources

### Exception Management

- **Domain Exceptions**: Handles business rule violations gracefully
- **Validation Errors**: Provides meaningful feedback for invalid operations
- **Resource Not Found**: Proper handling of missing entities

## Dependencies

The Application layer depends on:

- **Domain Layer**: Entities, value objects, and domain services
- **No External Frameworks**: Maintains framework independence
- **Abstractions Only**: Uses interfaces for Infrastructure concerns

## Testing Strategy

This layer is designed for comprehensive unit testing:

- **Mockable Dependencies**: All external dependencies are abstracted
- **Business Logic Focus**: Tests concentrate on business workflows
- **Integration Points**: Clear boundaries for integration testing
- **Isolated Testing**: No database or external service dependencies
