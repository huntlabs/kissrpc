

import std.stdio;
import kissrpc.RpcBuild;
import kissrpc.RpcManager;
import kissrpc.RpcClient;
import kissrpc.RpcConstant;

import kissrpc.RpcServer;
import kissrpc.RpcClient;
import kissrpc.RpcStream;



import kiss.exception;
import kiss.net.struct_;
import kiss.event.loop;
import kiss.net.TcpStreamClient;

import rpcgenerate.GreeterRequest;
import rpcgenerate.GreeterResponse;
import rpcgenerate.GreeterInterface;
import rpcgenerate.GreeterStub;


import core.thread;
import std.traits;
import std.experimental.logger.core;
import std.string;


void doClientTest(RpcClient client) {
    GreeterStub stub = new GreeterStub(client);
    GreeterResponse ret;
    GreeterRequest request;
    request.msg = "hello";
    ubyte[] exData;

    //sync call
    RpcResponseBody status = stub.SayHello(request, exData, ret);
    if (status.code == RpcProcCode.Success) {
        writeln("sync call success :", ret.msg);
    }
    else {
        writeln("sync call failed : ", ret.msg); 
    }

    //async call
    stub.SayHello(request, exData, (RpcResponseBody response, GreeterResponse r){
        if (response.code == RpcProcCode.Success) {
            writeln("async call success :", r.msg);
        }
        else {
            writeln("async call failed : ", r.msg); 
        }
    });
}


void main() {

    RpcClient client = RpcManager.getInstance().createRpcClient("0.0.0.0", 9000, (RpcStream stream, RpcEvent code, string msg){
        log("<-----------client event code = %s, msg = %s".format(code,msg));
    });
    doClientTest(client);
}

