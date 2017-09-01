


module KissRpc.RpcManager;

import KissRpc.RpcServer;
import kiss.aio.AsynchronousChannelThreadGroup;
import KissRpc.Logs;
import KissRpc.RpcServerListener;

import std.experimental.logger.core;


class RpcManager {

public:
    this() {

    }

    static @property getInstance() {
        if (_instance is null) {
            _instance = new RpcManager();
        }
        return _instance;
    }

    //T是RpcServerListener类或者子类 A是server端RPC类
    void startService(T, A...)(string ip, ushort port, int threadNum) {
        if(isServerStart)
        {
            warningf("rpc service has already start !!!");
            return;
        }
        isServerStart = true;
        _serverGroup = AsynchronousChannelThreadGroup.open(5,threadNum);
        for(int i = 0; i < threadNum; i++) {
            RpcServer service = new RpcServer(ip, port, _serverGroup,new T);
            foreach(t;A) {
                auto rpcClass = new t(service);
            }
        }
        _serverGroup.start();
    }

    void stopService() {
        isServerStart = false;
        _serverGroup.stop();
    }
    //T是RpcClientListener类 或者子类
    void connectService(T)(string ip, ushort port, int threadNum) {
        if(isClientStart)
        {
            warningf("rpc service has already start !!!");
            return;
        }
        isClientStart = true;
        _ClientGroup = AsynchronousChannelThreadGroup.open(5,threadNum);
        for(int i = 0; i < threadNum; i++) {
            T client = new T(ip, port, _ClientGroup.getWorkSelector());
        }
        _ClientGroup.start();
    }
    void stopClient() {
        isClientStart = false;
        _ClientGroup.stop();
    }

private :
    __gshared static RpcManager _instance;
    AsynchronousChannelThreadGroup _serverGroup;
    AsynchronousChannelThreadGroup _ClientGroup;

    bool isServerStart;
    bool isClientStart;
}