

module kissrpc.RpcStreamServer;

import kissrpc.RpcBase;
import kissrpc.RpcProxy;
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
        startHeartbeat();
    }
    override void doHeartbeatTimer() {
        if (_timeoutCount > 0) {
            _timeoutCount--;
        }
        if (_timeoutCount == 0) {
            doHandlerEvent(RpcEvent.HeartbeatClose, "does not receive client hearbeat request, connection close!!!");
            _timeoutCount = _rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
        }
    }
    //处理rpc事件
    override void doHandlerEvent(RpcEvent event, string msg) @trusted nothrow {
        catchAndLogException((){
            if (event == RpcEvent.RecvHeartbeat) {
                _timeoutCount = _rpcBase.getSetting(RpcSetting.HeartbeatTimeoutCount);
                RpcHeadData head = getHead();
                RpcContentData content;
                writeRpcData(head, content);
            }
            super.doHandlerEvent(event, msg);
        }());
    }
    override void dealWithFullData(RpcHeadData head, RpcContentData content) {
        RpcProxy.invokerRequest(content.msg, content.data, content.exData, head.protocol, head.clientSeqId, this);
    }
protected:
    override void onClose(Watcher watcher) nothrow {
        doHandlerEvent(RpcEvent.Close, "disconnected from client");
        super.onClose(watcher);
    }
private:
    int _timeoutCount;
}