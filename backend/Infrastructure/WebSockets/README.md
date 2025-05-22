# WebSocket Implementation with Fleck

## Overview

The WebSocket implementation uses Fleck to provide real-time communication between the server and clients. This enables instant notifications for calendar events, employee changes, and other updates.

## Connection Details

- **WebSocket URL**: `ws://localhost:8181` (or configured host/port)
- **Secure WebSocket**: `wss://localhost:8181` (when SecureConnection is enabled)

Note: The WebSocket server runs directly on the specified port using Fleck, not through the ASP.NET Core middleware.

## Authentication Protocol

1. **Connect** to the WebSocket server at port 8181
2. **Authenticate** by sending a session message:
   ```json
   {
     "type": "session",
     "sessionId": "your-session-id-from-login"
   }
   ```
3. **Set Company Context** after successful authentication:
   ```json
   {
     "type": "setcompany",
     "data": {
       "companyId": "00000000-0000-0000-0000-000000000000"
     }
   }
   ```

## Message Types

### Sent from server to client:

- **AuthenticationResult** - Authentication response
- **EventCreated** - When a new calendar event is created
- **EventUpdated** - When a calendar event is modified
- **EventDeleted** - When a calendar event is removed
- **EmployeeAdded** - When a new employee is added to the company
- **EmployeeRemoved** - When an employee is removed
- **CompanyUpdated** - When company information changes

## Reconnection Strategy

The Flutter client implements an exponential backoff strategy for reconnection attempts with a maximum of 5 retries.
