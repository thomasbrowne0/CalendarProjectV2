namespace API.Proxy
{
    /* We need this interface because the proxy server configuration might need to be mocked
       or replaced with different implementations during testing or different deployment scenarios */
    public interface IProxyConfig
    {
        void StartProxyServer(int publicPort, int restPort, int wsPort);
    }
}