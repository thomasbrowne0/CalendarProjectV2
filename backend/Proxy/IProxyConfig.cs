namespace backend.Proxy

public interface IProxyConfig
{
    void StartProxyServer(int publicPort, int restPort, int wsPort);
}