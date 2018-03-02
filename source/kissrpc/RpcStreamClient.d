


module kissrpc.RpcStreamClient;

import kissrpc.RpcBase;
import kissrpc.RpcProxy;
import kissrpc.RpcClient;
import kissrpc.RpcStream;
import kissrpc.RpcConstant;

import kiss.net.Timer;
import kiss.event.base;
import kiss.exception;

import std.socket;
import std.exception;
import std.experimental.logger.core;


alias RpcCallBack = void delegate(RpcResponseBody response, ubyte[] data, ubyte protocol); 

class RpcStreamClient : RpcStream {
public:
    this(long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        _reconnectTimes = rpcBase.getSetting(RpcSetting.ConnectCount);
        _timeoutCount = rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
        super(streamId, rpcBase, handler);
        setConnectHandle((bool connected) @trusted nothrow {
            if (connected)
                doHandlerEvent(RpcEvent.ConnectSuccess, "connect success");
            else 
                doHandlerEvent(RpcEvent.ConnectFailed, "connect server failed");
        });
    }

    bool connect() {
        bool enable = super.connect(parseAddress(_rpcBase.getHost(), _rpcBase.getPort()));
        if (enable) {
            createTimer(_connectTimeoutTimer, _rpcBase.getSetting(RpcSetting.ConnectTimeout), (){
                if (!isConnected()){
                    doHandlerEvent(RpcEvent.ConnectTimeout, "connect timeout");
                }
                else {
                    _connectTimeoutTimer.stop();
                }
            });           
        }
        return enable;
    }
    //处理客户端重连
    void reconnect() {
        if (_reconnectTimes == 0)
            return;
        createTimer(_reconnectIntervalTimer, _rpcBase.getSetting(RpcSetting.ConnectInterval), (){
                log("dealWithReconnect");
                if (_reconnectTimes > 0)
                    _reconnectTimes--;
                resetWatcher();
                connect();
                _reconnectIntervalTimer.stop();
            });
    }

  
    override void doBeartbeatTimer() {
        if (_timeoutCount > 0)
            _timeoutCount--;

        if (_timeoutCount == 0) {
            doHandlerEvent(RpcEvent.HeartbeatClose, "does not receive server hearbeat response, connection close!!!");
            _timeoutCount = _rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
        }
        else {
            RpcHeadData head = (cast(RpcClient)_rpcBase).getDefaultHead();
            RpcContentData content;
            writeRpcData(head, content);
        }
    }
    //处理rpc事件
    override void doHandlerEvent(RpcEvent event, string msg) @trusted nothrow {
        catchAndLogException((){
            if (event == RpcEvent.ConnectSuccess) {
                _reconnectTimes = _rpcBase.getSetting(RpcSetting.ConnectCount);
                stopTimer(_connectTimeoutTimer);
                stopTimer(_reconnectIntervalTimer);
            }
            else if (event == RpcEvent.ConnectFailed || event == RpcEvent.ConnectTimeout) {
                collectExceptionMsg(eventLoop().deregister(_watcher));
                stopTimer(_connectTimeoutTimer);
                reconnect();
            }
            else if (event == RpcEvent.RecvHeartbeat) {
                _timeoutCount = _rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
            }
            else if (event == RpcEvent.Close) {
                foreach(k,v; _callbackMap) {
                    ubyte[] data;
                    ubyte[] exData;
                    RpcProxy.invokerResponse("conection close", data, exData, getHead().protocol, getHead().clientSeqId, this, RpcProcCode.SendFailed);
                    _callbackMap.remove(k);
                }
            }
            super.doHandlerEvent(event, msg);
        }());
    }

    override void dealWithFullData(RpcHeadData head, RpcContentData content) {
        RpcProxy.invokerResponse(content.msg, content.data, content.exData, head.protocol, head.clientSeqId, this, head.code);
    }


    void addRequestCallback(ulong reqId, RpcCallBack cb) {
        synchronized(this) {
            _callbackMap[reqId] = cb;
        }
    }
    RpcCallBack getRequestCallback(ulong reqId) {
        synchronized(this) {
            if (reqId in _callbackMap) {
                return _callbackMap[reqId];
            }
            return null;
        }
    }  
    void removeRequestCallback(ulong reqId) {
        synchronized(this) {
            if (reqId in _callbackMap) {
                _callbackMap.remove(reqId);
            }
        }
    }

protected:
    override void onClose(Watcher watcher) nothrow { 
        doHandlerEvent(RpcEvent.Close, "disconnected from server");
        super.onClose(watcher);
    }
private: 

    void stopTimer(Timer timer) {
        if (timer)
            timer.stop();
    }
    void createTimer(ref Timer timer, int interval, void delegate() func) {
        if (timer is null)
            timer = new Timer(_rpcBase.getLoop());
        else 
            timer.stop();
        timer.setTimerHandle(()@trusted nothrow {
                catchAndLogException((){
                    func();
                }());
            }).start(interval);
    }
private:
    int _timeoutCount;
    int _reconnectTimes;  //重连剩余次数
    Timer _connectTimeoutTimer;    //连接超时 timer
    Timer _reconnectIntervalTimer;  //连接重试 timer

    RpcCallBack[ulong] _callbackMap;
}

