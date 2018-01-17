






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
        return createRpc!(RpcServer)(host, port, handler);
    }
    RpcClient createRpcClient(string host, ushort port, RpcEventHandler handler = null) {
        return createRpc!(RpcClient)(host, port, handler);
    }
    T createRpc(T)(string host, ushort port, RpcEventHandler handler) {
        synchronized (this) {
            EventLoop loop = new EventLoop();
            T t = new T(loop, host, port, handler);
            static if (is(T == RpcClient)) {
                _clients[_clientIndex] = t;
                _clientIndex++;
            }
            else {
                _servers[_serverIndex] = t;
                _serverIndex++;
            }
            new Thread({
                t.start();
            }).start();
            return t;
        }
    }
private:
    int _serverIndex;
    int _clientIndex;
    RpcClient[int] _clients;
    RpcServer[int] _servers;
    __gshared static RpcManager _instance;
}