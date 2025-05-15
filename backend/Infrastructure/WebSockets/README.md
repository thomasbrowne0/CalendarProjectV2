# WebSocket Implementation with Fleck

## Overview

The WebSocket implementation uses Fleck to provide real-time communication between the server and clients. This enables instant notifications for calendar events, employee changes, and other updates.

## Connection Details

- **WebSocket URL**: `ws://{server-address}:8181` (or the configured port)
- **Secure WebSocket**: `wss://{server-address}:8181` (when SecureConnection is enabled)

## Authentication Protocol

1. **Connect** to the WebSocket server
2. **Authenticate** by sending a message with your JWT token:
   ```json
   {
     "type": "authenticate",
     "token": "your.jwt.token"
   }
   ```
3. **Set Company Context** after successful authentication:
   ```json
   {
     "type": "setCompany",
     "data": {
       "companyId": "00000000-0000-0000-0000-000000000000"
     }
   }
   ```

## Received Message Types

The server will send messages with the following types:

- **EventCreated** - When a new calendar event is created
- **EventUpdated** - When a calendar event is modified
- **EventDeleted** - When a calendar event is removed
- **EmployeeAdded** - When a new employee is added to the company
- **EmployeeRemoved** - When an employee is removed
- **EmployeeUpdated** - When employee details are updated
- **CompanyUpdated** - When company information changes

## Message Format

All messages follow this JSON format:

```json
{
  "Type": "MessageType",
  "Data": {
    // Message-specific properties
  }
}
```

## Example Client Implementation

```javascript
// Example JavaScript implementation
const socket = new WebSocket('ws://localhost:8181');

socket.onopen = () => {
  console.log('Connected to WebSocket server');
  // Authenticate with the server
  socket.send(JSON.stringify({
    type: 'authenticate',
    token: 'your.jwt.token'
  }));
};

socket.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received message:', message);
  
  switch (message.Type) {
    case 'AuthenticationResult':
      if (message.Success) {
        console.log('Authentication successful');
        // Set company context
        socket.send(JSON.stringify({
          type: 'setCompany',
          data: {
            companyId: 'your-company-guid'
          }
        }));
      }
      break;
    case 'EventCreated':
      console.log('New event created:', message.Data.EventId);
      break;
    // Handle other message types
  }
};

socket.onclose = () => {
  console.log('Connection closed');
};

socket.onerror = (error) => {
  console.error('WebSocket error:', error);
};
```
