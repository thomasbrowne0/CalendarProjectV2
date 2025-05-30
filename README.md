# Calendar Project V2

A comprehensive company calendar management system built with Clean Architecture principles, featuring real-time
collaboration through WebSocket communication.

Running backend deployment:  https://calendar-backend-503012500647.europe-north1.run.app
Running frontend deployment: https://calendarfrontend-e6233.web.app/

## 🏗️ Architecture Overview

This project implements **Clean Architecture (Onion Architecture)** with clear separation of concerns across multiple
layers:

### Backend (.NET 9)

- **API Layer**: RESTful endpoints and WebSocket communication
- **Application Layer**: Business logic orchestration and use cases
- **Domain Layer**: Core business entities and rules
- **Infrastructure Layer**: Data persistence and external services

### Frontend (Flutter)

- **Presentation Layer**: Flutter widgets and screens
- **State Management**: BLoC/Cubit pattern with Provider
- **Services Layer**: API communication and WebSocket handling
- **Models Layer**: Data transfer objects and domain models

## 🚀 Key Features

### Core Functionality

- **Multi-Company Support**: Company owners can manage multiple companies
- **Employee Management**: Role-based access control (Company Owners vs Employees)
- **Calendar Events**: Create, update, and delete calendar events with participant management
- **Real-time Updates**: WebSocket-powered instant notifications across all connected clients
- **Date Range Filtering**: Efficient event querying with UTC handling
- **Responsive Design**: Modern Flutter UI that works across devices

### Authentication & Authorization

- **JWT-based Authentication**: Secure token-based authentication
- **Role-based Access**: Company owners and employees have different permissions
- **Company Boundary Enforcement**: Users can only access data within their company scope

### Real-time Communication

- **WebSocket Integration**: Live updates for calendar events and employee changes
- **Company-scoped Messaging**: Notifications are delivered only to relevant company members
- **Connection Management**: Automatic reconnection and connection state handling

## 🛠️ Technology Stack

### Backend

- **.NET 9**: Modern C# web API framework
- **Entity Framework Core**: ORM with PostgreSQL database
- **Fleck**: WebSocket server implementation
- **JWT Authentication**: Secure token-based authentication
- **PostgreSQL**: Production-ready relational database

### Frontend

- **Flutter**: Cross-platform UI framework
- **BLoC/Cubit**: State management pattern
- **Provider**: Dependency injection and state sharing
- **Table Calendar**: Interactive calendar component
- **WebSocket Channel**: Real-time communication
- **HTTP**: RESTful API communication

## 📁 Project Structure

```
CalendarProjectV2/
├── backend/                    # .NET Backend
│   ├── API/                   # Controllers and web configuration
│   ├── Application/           # Business logic and DTOs
│   ├── Domain/               # Core entities and interfaces
│   └── Infrastructure/       # Data access and WebSocket services
├── frontend/                  # Flutter Frontend
│   └── calendar_app/         # Main Flutter application
│       ├── lib/
│       │   ├── screens/      # UI screens
│       │   ├── widgets/      # Reusable UI components
│       │   ├── providers/    # State management
│       │   ├── services/     # API and business services
│       │   ├── models/       # Data models
│       │   └── cubit/        # BLoC state management
│       └── web/              # Web-specific assets
└── firebase.json             # Firebase hosting configuration
```

## 🔧 Setup & Installation

### Prerequisites

- .NET 9 SDK
- Flutter SDK (>=3.0.0)
- PostgreSQL Database
- Firebase CLI (for deployment)

### Backend Setup

1. **Database Configuration**
   ```bash
   cd backend
   # Update connection string in appsettings.json
   dotnet ef database update
   ```

2. **Run Backend Services**
   ```bash
   dotnet run --project API
   # Backend API: https://localhost:7071
   # WebSocket Server: ws://localhost:8181
   ```

### Frontend Setup

1. **Install Dependencies**
   ```bash
   cd frontend/calendar_app
   flutter pub get
   ```

2. **Run Development Server**
   ```bash
   flutter run -d web
   ```

3. **Build for Production**
   ```bash
   flutter build web
   ```

### Firebase Deployment

1. **Deploy to Firebase Hosting**
   ```bash
   # From project root
   flutter build web
   firebase deploy
   ```

## 🎯 Usage

### Company Owner Workflow

1. **Register** as a company owner
2. **Create Companies** with unique CVR numbers
3. **Add Employees** to companies
4. **Manage Calendar Events** with employee participants
5. **Real-time Monitoring** of all company activities

### Employee Workflow

1. **Login** with credentials provided by company owner
2. **View Company Calendar** events
3. **See Colleagues** within the same company
4. **Participate** in calendar events
5. **Receive Real-time Updates** for calendar changes

## 🔒 Security Features

- **JWT Token Authentication**: Secure API access
- **Company Data Isolation**: Users can only access their company's data
- **Role-based Authorization**: Different permissions for owners vs employees
- **Input Validation**: Comprehensive validation at all layers
- **SQL Injection Protection**: Entity Framework Core parameterized queries

## 🌐 API Endpoints

### Authentication

- `POST /api/auth/login` - User authentication
- `POST /api/auth/register` - Company owner registration

### Company Management

- `GET /api/companies/{ownerId}` - Get companies by owner
- `GET /api/companies/{id}` - Get company details

### Employee Management

- `GET /api/companies/{companyId}/employees` - Get company employees
- `POST /api/companies/{companyId}/employees` - Add new employee

### Calendar Events

- `GET /api/companies/{companyId}/events` - Get company events (with date filtering)
- `POST /api/companies/{companyId}/events` - Create new event
- `PUT /api/companies/{companyId}/events/{id}` - Update event
- `DELETE /api/companies/{companyId}/events/{id}` - Delete event

## 📡 WebSocket Communication

### Connection

- **URL**: `ws://localhost:8181`
- **Authentication**: JWT token required
- **Scope**: Company-based message filtering

### Message Types

- `event_created` - New calendar event notifications
- `event_updated` - Calendar event modifications
- `event_deleted` - Calendar event removals
- `employee_added` - New employee notifications
- `company_updated` - Company information changes

## 🧪 Development Patterns

### Clean Architecture Benefits

- **Testability**: Business logic is isolated and easily testable
- **Maintainability**: Clear separation of concerns
- **Flexibility**: Easy to swap implementations (database, UI, etc.)
- **Scalability**: Well-organized codebase that grows maintainably

### State Management

- **BLoC Pattern**: Predictable state management with clear events and states
- **Provider**: Dependency injection and widget state sharing
- **Real-time Integration**: WebSocket messages automatically update UI state

## 🚀 Deployment

### Backend Deployment

- Containerized with Docker support
- PostgreSQL database configuration
- Environment-specific settings (Development/Production)

### Frontend Deployment

- Firebase Hosting for web deployment
- Optimized Flutter web build
- Progressive Web App (PWA) capabilities

## 📈 Future Enhancements

- **Mobile Apps**: Native iOS and Android applications
- **Email Notifications**: Event reminders and updates
- **Recurring Events**: Support for repeating calendar events
- **File Attachments**: Document sharing within events
- **Advanced Permissions**: Fine-grained access control
- **Analytics Dashboard**: Company usage insights

## 🤝 Contributors

Barnabas Tamas
Radwan El Chaar
Yordan Rusev

## 📄 License

This project is developed as part of an academic examination submission.
