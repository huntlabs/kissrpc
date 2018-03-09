


import kissrpc;

import rpcgenerate.greeter;


import std.string;


final class GreeterService : Greeter {
    mixin MakeRpc;
public:
    override GreeterResponse SayHello(GreeterRequest message) {
        GreeterResponse msg;
        msg.msg = message.msg;
        log("rpc exData = ",getRpcExData());

        setRpcExData([2,1]);
        return msg;
    }
    override GreeterResponse getSayHello() {
        GreeterResponse msg;
        msg.msg = "getSayHello";
        log("rpc exData = ",getRpcExData());
        setRpcExData([2,1]);
        return msg;
    }

}

void main() {
    RpcServer server = RpcManager.getInstance().createRpcServer("0.0.0.0", 9009, (RpcStream stream, RpcEvent code, string msg){
        log("~~~~~~~~~server event code = %s, msg = %s".format(code,msg));
    });
}

