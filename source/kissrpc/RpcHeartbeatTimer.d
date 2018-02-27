

module kissrpc.RpcHeartbeatTimer;

import kissrpc.RpcStream;

import kiss.timingwheel;

@trusted class RpcHeartbeatTimer : WheelTimer{
public:
    this(RpcStream stream) {
        _stream = stream;
    }
    override void onTimeOut() nothrow
    {

    }
private:
    RpcStream _stream;
}