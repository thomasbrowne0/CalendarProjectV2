# Domain Layer

## Overview

The Domain Layer represents the **innermost layer** of our Clean Architecture implementation and contains the core business logic, entities, and rules of the Calendar Project V2. This layer is completely independent of external frameworks, databases, or UI concerns.

## Architecture Principles

This layer follows Clean Architecture principles by:
- **Framework Independence**: Contains no references to external frameworks
- **Database Independence**: No knowledge of persistence mechanisms
- **UI Independence**: No coupling to user interface concerns
- **Testability**: Highly testable due to minimal dependencies
- **Business Logic Focus**: Pure business rules and domain knowledge

## Core Components

### Domain Entities

#### User (Abstract Base Class)
- **Purpose**: Base class for all user types in the system
- **Key Features**: Secure password management, email validation, update operations
- **Inheritance**: Extended by CompanyOwner and Employee
- **Security**: Protected properties with controlled access

#### CompanyOwner
- **Purpose**: Represents business owners who can manage companies and employees
- **Capabilities**: Create companies, manage business operations
- **Relationships**: One-to-many with Company entities
- **Business Rules**: Can own multiple companies

#### Employee
- **Purpose**: Represents company staff members with limited permissions
- **Capabilities**: Participate in calendar events, update personal information
- **Relationships**: Belongs to one company, participates in many events
- **Business Rules**: Company-scoped access, job title management

#### Company
- **Purpose**: Central business entity representing organizations
- **Key Features**: CVR (company registration) validation, employee management
- **Relationships**: Owned by CompanyOwner, contains Employees
- **Business Rules**: Unique CVR requirement, ownership validation

#### CalendarEvent
- **Purpose**: Represents scheduled business events and meetings
- **Key Features**: Time validation, participant management, company isolation
- **Relationships**: Created by User, belongs to Company, has Employee participants
- **Business Rules**: Time constraints, company-scoped participants

### Repository Interfaces

#### Core Repository Abstractions
- **IRepository<T>**: Generic repository pattern with CRUD operations
- **IUserRepository**: User-specific operations with email-based lookup
- **ICompanyRepository**: Company management with CVR validation
- **IEmployeeRepository**: Employee operations within company boundaries
- **ICalendarEventRepository**: Event management with complex querying capabilities
- **ICompanyOwnerRepository**: Company owner specific operations

#### Advanced Repository Features
- **Async Operations**: All repository methods support asynchronous execution
- **Complex Queries**: Support for date ranges, company filtering, participant management
- **Validation**: Built-in business rule validation at repository level

### Service Interfaces

#### Business Service Contracts
- **IUnitOfWork**: Transaction coordination and change tracking
- **ICalendarService**: Calendar-specific business operations
- **ICompanyService**: Company management business logic
- **IUserService**: User lifecycle and authentication services

## Business Rules & Domain Logic

### User Management Rules
1. **Email Uniqueness**: All users must have unique email addresses across the system
2. **Password Security**: Passwords must be properly hashed and validated
3. **User Type Inheritance**: Clear distinction between CompanyOwner and Employee roles
4. **Profile Management**: Controlled update operations with validation

### Company Business Rules
1. **CVR Uniqueness**: Company registration numbers must be unique
2. **Ownership Model**: Each company has exactly one owner
3. **Employee Boundaries**: Employees belong to exactly one company
4. **Data Isolation**: Company data is strictly isolated between organizations

### Calendar Event Rules
1. **Time Validation**: Events must have valid start and end times
2. **Participant Restrictions**: Only company employees can participate in company events
3. **Creator Authorization**: Events can only be created by company members
4. **Cross-Company Isolation**: Events cannot span multiple companies

### Employee Management Rules
1. **Company Association**: Employees must be associated with exactly one company
2. **Job Title Requirements**: All employees must have defined job titles
3. **Contact Information**: Mobile phone numbers are optional but validated when provided
4. **Permission Boundaries**: Employees cannot access other companies' data

## Domain Events & Validation

### Entity Validation
- **Constructor Validation**: All entities validate input during creation
- **Business Rule Enforcement**: Domain logic prevents invalid states
- **Invariant Protection**: Entities maintain consistency throughout their lifecycle
- **Error Handling**: Domain-specific exceptions for business rule violations

### Data Integrity
- **Referential Integrity**: Proper relationships between entities
- **Cascade Operations**: Controlled deletion and update propagation
- **State Consistency**: Entities maintain valid states across operations
- **Transaction Boundaries**: Clear transaction scope definitions

## Value Objects & Primitives

### Key Value Objects
- **Email Addresses**: Validated email format and uniqueness
- **Company Registration (CVR)**: Validated Danish company registration numbers
- **Date/Time Handling**: UTC-based time management for global consistency
- **User Credentials**: Secure password hashing and validation

### Primitive Validation
- **String Validation**: Non-null and non-empty string requirements
- **GUID Management**: Proper unique identifier generation and validation
- **DateTime Handling**: Consistent UTC time zone management
- **Collection Management**: Proper initialization and manipulation of entity collections

## Exception Handling

### Domain-Specific Exceptions
- **DomainException**: Base exception for all domain-related errors
- **Validation Exceptions**: Input validation and business rule violations
- **Business Logic Exceptions**: Complex business rule enforcement
- **State Exceptions**: Invalid entity state transitions

### Error Patterns
- **Guard Clauses**: Defensive programming with early validation
- **Fail-Fast**: Immediate failure on invalid operations
- **Meaningful Messages**: Clear error descriptions for troubleshooting
- **Exception Hierarchy**: Structured exception types for different error categories

## Testing Strategy

### Domain Testing Approach
- **Unit Testing**: Comprehensive testing of entity behavior and business rules
- **Business Logic Testing**: Validation of complex domain operations
- **Rule Testing**: Verification of business rule enforcement
- **Edge Case Testing**: Testing boundary conditions and error scenarios

### Test Independence
- **No External Dependencies**: Domain tests require no database or external services
- **Pure Business Logic**: Tests focus on business behavior validation
- **Isolated Testing**: Each entity and service can be tested in isolation
- **Mock-Free Testing**: Minimal need for mocking due to clean dependencies

## Design Patterns

### Implemented Patterns
- **Repository Pattern**: Data access abstraction for persistence ignorance
- **Unit of Work**: Transaction coordination across multiple repositories
- **Domain Model**: Rich domain objects with encapsulated business logic
- **Abstract Factory**: User type creation through inheritance hierarchy

### SOLID Principles
- **Single Responsibility**: Each entity has one clear business purpose
- **Open/Closed**: Extensible design through interfaces and inheritance
- **Liskov Substitution**: Proper inheritance hierarchies
- **Interface Segregation**: Focused, single-purpose interfaces
- **Dependency Inversion**: Dependencies on abstractions, not concretions

## Future Extensibility

### Extension Points
- **New User Types**: Easy addition of new user roles through inheritance
- **Additional Business Rules**: Extensible validation and business logic
- **New Entity Types**: Clear patterns for adding new domain entities
- **Enhanced Relationships**: Support for complex entity relationships

### Scalability Considerations
- **Performance**: Efficient entity design for large-scale operations
- **Memory Management**: Optimized entity lifecycle and garbage collection
- **Query Optimization**: Repository patterns support efficient data access
- **Caching Support**: Entity design enables effective caching strategies
