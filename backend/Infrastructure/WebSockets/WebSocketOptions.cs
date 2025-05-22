using System;

namespace Infrastructure.WebSockets
{
    public class WebSocketOptions
    {
        public string Host { get; set; } = "0.0.0.0";
        public int Port { get; set; } = 8080;
        public bool SecureConnection { get; set; } = false;
        public string CertificatePath { get; set; } = string.Empty;
        public string CertificatePassword { get; set; } = string.Empty;
    }
}
