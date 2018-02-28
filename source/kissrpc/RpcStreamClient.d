


module kissrpc.RpcStreamClient;

import kissrpc.RpcBase;
import kissrpc.RpcStream;
import kissrpc.RpcConstant;

import kiss.net.Timer;
import kiss.event.base;
import kiss.exception;

import std.socket;
import std.exception;
import std.experimental.logger.core;

class RpcStreamClient : RpcStream {
public:
    this(long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        _reconnectTimes = rpcBase.getSetting(RpcSetting.ConnectCount);
        super(streamId, rpcBase, handler);
    }

    bool connect() {
        bool enable = watch();
        if (enable) {
            enable = eventLoop().connect(_watcher,parseAddress(_rpcBase.getHost(), _rpcBase.getPort()));
            //连接超时
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

    bool isConnected() {
        return _isConnected;
    }

    override void doBeartbeatTimer() {
        
    }
protected:
    override void onClose(Watcher watcher) nothrow { 
        if (!_isConnected) {
            doHandlerEvent(RpcEvent.ConnectFailed, "connect server failed");
            return;
        }
        doHandlerEvent(RpcEvent.Close, "disconnected from server");
        _isConnected = false;
        super.onClose(watcher);
    }
    override void onWrite(Watcher watcher) nothrow{
        if (!_isConnected) {
            _isConnected = true;
            doHandlerEvent(RpcEvent.ConnectSuccess, "connect success");
            return; 
        }
        super.onWrite(watcher);
    }

private: 
    //处理rpc事件
    void doHandlerEvent(RpcEvent event, string msg) @trusted nothrow {
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
                
            }
            super.doHandlerEvent(event, msg);
        }());
    }

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
    bool _isConnected;
    int _reconnectTimes;  //重连剩余次数
    Timer _connectTimeoutTimer;    //连接超时 timer
    Timer _reconnectIntervalTimer;  //连接重试 timer
}

