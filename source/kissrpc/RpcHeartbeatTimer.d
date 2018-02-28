

module kissrpc.RpcHeartbeatTimer;

import kissrpc.RpcStream;

import kiss.exception;
import kiss.timingwheel;

@trusted class RpcHeartbeatTimer : WheelTimer{
    void setCallback(void delegate() @trusted func) {
        _func = func;
    }
    override void onTimeOut() nothrow
    {
        catchAndLogException((){
            if (_func) 
                _func();
        }());
    }
private:
    void delegate() @trusted _func;
}