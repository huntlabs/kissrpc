

module rpcgenerate.greeter.GreeterStub;

import rpcgenerate.greeter.Greeter;

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
        RpcResponseBody response;
        ret = _rpcClient.call!(GreeterResponse, GreeterRequest)(response, "Greeter.SayHello", exData, message);
        return response;
    }
    RpcResponseBody getSayHello(ubyte[] exData, ref GreeterResponse ret) { 
        RpcResponseBody response;
        _rpcClient.call!(GreeterResponse)(response, "Greeter.getSayHello", exData);
        return response;
    }

    //async function
    void SayHello(GreeterRequest message,  ubyte[] exData, void delegate(RpcResponseBody response, GreeterResponse r) func) {
        _rpcClient.call!(GreeterResponse, GreeterRequest)("Greeter.SayHello", exData, (RpcResponseBody response, GreeterResponse r){
            func(response, r);
        }, message);
    }

    //async function
    void getSayHello(ubyte[] exData, void delegate(RpcResponseBody response, GreeterResponse r) func) {
        _rpcClient.call!(GreeterResponse)("Greeter.getSayHello", exData, (RpcResponseBody response, GreeterResponse r){
            func(response, r);
        });
    }

private:
    RpcClient _rpcClient;
}