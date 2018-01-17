

module rpcgenerate.GreeterStub;

import rpcgenerate.GreeterRequest;
import rpcgenerate.GreeterResponse;

import kissrpc.RpcConstant;
import kissrpc.RpcClient;



//for client
final class GreeterStub {
public:
    
    this(RpcClient client) {
        _rpcClient = client;
    }
    
    //sync function
    RpcResponseBody SayHello(GreeterRequest message, ubyte[] exData, ref GreeterResponse ret) {
        return _rpcClient.call!(GreeterRequest, GreeterResponse)("Greeter.SayHello", message, exData, ret);
    }
    
    //async function
    void SayHello(GreeterRequest message,  ubyte[] exData, void delegate(RpcResponseBody response, GreeterResponse r) func) {
        _rpcClient.call!(GreeterRequest, GreeterResponse)("Greeter.SayHello", message, exData, (RpcResponseBody response, GreeterResponse r){
            func(response, r);
        });
    }

private:
    RpcClient _rpcClient;
}