






module kissrpc.RpcManager;

import kissrpc.RpcClient;
import kissrpc.RpcServer;
import kissrpc.RpcConstant;

import kiss.event.loop;
import kissrpc.RpcStream;
import kiss.net.TcpListener;

import core.thread;

final class RpcManager {

public:
    this() {}
    static @property getInstance() {
        if (_instance is null) {
            _instance = new RpcManager();
        }
        return _instance;
    }
    RpcServer createRpcServer(string host, ushort port, RpcEventHandler handler = null) {   
        synchronized (this) {
            EventLoop loop = new EventLoop();
            RpcServer server = new RpcServer(loop, host, port, handler);
            _servers[_serverIndex] = server;
            _serverIndex++;
            return server;
        }
    }
    RpcClient createRpcClient(string host, ushort port, RpcConnectCb cb, RpcEventHandler handler = null) {
        synchronized (this) {
            EventLoop loop = new EventLoop();
            RpcClient client = new RpcClient(loop, host, port, handler);
            _clients[_clientIndex] = client;
            _clientIndex++;
            client.setConnectHandle(cb);
            return client;
        }
    }
private:
    int _serverIndex;
    int _clientIndex;
    RpcClient[int] _clients;
    RpcServer[int] _servers;
    __gshared static RpcManager _instance;
}