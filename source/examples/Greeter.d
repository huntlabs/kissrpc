

module rpc.Greeter;

import kissrpc.RpcConstant;
import kissrpc.RpcClient;

import example.GreeterMessage;
import example.GreeterRequestFb;
import example.GreeterResponseFb;

import std.traits;
import std.experimental.logger.core;

//for client
final class GreeterStub : Greeter {
public:
    
    this(RpcClient client) {
        _rpcClient = client;
    }

    override GreeterResponse SayHello(GreeterRequest message) {
        GreeterResponse response;
        return response;
    }
    
    //sync function
    RpcResponseBody SayHello(GreeterRequest message, ref GreeterResponse ret) {
        RpcResponseBody response;
        return response;
    }
    
    //async function
    void SayHello(GreeterRequest message, void delegate(RpcResponseBody response, GreeterResponse r) func) {
        ubyte[] exData;
        _rpcClient.call!(GreeterRequest,GreeterResponse)("Greeter.SayHello", message, (RpcResponseBody response, GreeterResponse r){
            func(response, r);
        }, exData);
    }

private:
    RpcClient _rpcClient;
}