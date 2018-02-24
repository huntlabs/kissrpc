


import kissrpc;

import rpcgenerate.GreeterRequest;
import rpcgenerate.GreeterResponse;
import rpcgenerate.GreeterStub;


import std.string;
import core.thread;


void doClientTest(RpcClient client) {
    GreeterStub stub = new GreeterStub(client);
    GreeterResponse ret;
    GreeterRequest request;
    request.msg = "hello";
    ubyte[] exData;

    //sync call
    RpcResponseBody status = stub.SayHello(request, exData, ret);
    if (status.code == RpcProcCode.Success) {
        log("sync call success :", ret.msg);
    }
    else {
        log("sync call failed : ", status.msg); 
    }

    //async call
    stub.SayHello(request, exData, (RpcResponseBody response, GreeterResponse r){
        if (response.code == RpcProcCode.Success) {
            log("async call success :", r.msg);
        }
        else {
            log("async call failed : ", response.msg); 
        }
    });
}


void main() {
    RpcClient client;
    client = RpcManager.getInstance().createRpcClient("0.0.0.0", 9009, (RpcStream stream, RpcEvent code, string msg){
        log("~~~~~~~~~client event code = %s, msg = %s".format(code,msg));
        if (code == RpcEvent.ConnectSuccess) {
            new Thread({
                doClientTest(client);
            }).start();
        }
    });
}

