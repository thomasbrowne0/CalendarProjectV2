using System;
using System.Net.WebSockets;
using System.Threading.Tasks;

namespace Application.Interfaces
{
    public interface IWebSocketService
    {
        Task HandleWebSocketConnectionAsync(WebSocket webSocket, Guid userId, string userType);
        Task NotifyCompanyDataChangedAsync(Guid companyId, string changeType, object data);
        Task NotifyEventCreatedAsync(Guid companyId, Guid eventId);
        Task NotifyEventUpdatedAsync(Guid companyId, Guid eventId);
        Task NotifyEventDeletedAsync(Guid companyId, Guid eventId);
        Task NotifyEmployeeAddedAsync(Guid companyId, Guid employeeId);
        Task NotifyEmployeeRemovedAsync(Guid companyId, Guid employeeId);
        Task ProxyToFleckAsync(WebSocket webSocket, string fleckUrl);
    }
}