

module kissrpc.RpcStreamServer;

import kissrpc.RpcBase;
import kissrpc.RpcStream;
import kissrpc.RpcConstant;

import kiss.net.Timer;
import kiss.exception;
import kiss.event.base;

import std.socket;
import std.experimental.logger.core;


class RpcStreamServer : RpcStream {
public:
    this(Socket sock, long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        super(sock, streamId, rpcBase, handler);
        _timeoutCount = rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
    }
    override void doBeartbeatTimer() {
        log("doBeartbeatTimer");
        if (_timeoutCount > 0) {
            _timeoutCount--;
        }
        if (_timeoutCount == 0) {
            doHandlerEvent(RpcEvent.HeartbeatClose, "does not receive client hearbeat, connection close!!!");
        }
    }
protected:
    override void onClose(Watcher watcher) nothrow {
        doHandlerEvent(RpcEvent.Close, "disconnected from client");
        super.onClose(watcher);
    }
private:
    //处理rpc事件
    void doHandlerEvent(RpcEvent event, string msg) @trusted nothrow {
        catchAndLogException((){
            if (event == RpcEvent.RecvHeartbeat) {
                _timeoutCount = _rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
            }
            super.doHandlerEvent(event, msg);
        }());
    }

private:
    int _timeoutCount;
}