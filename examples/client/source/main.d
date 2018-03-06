


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
    ubyte[] exData = [1,2];

    //sync call
    RpcResponseBody status = stub.SayHello(request, exData, ret);
    if (status.code == RpcProcCode.Success) {
        log("sync call SayHello success :", ret.msg);
        log("sync call SayHello exData :", status.exData);
    }
    else {
        log("sync call failed : ", status.msg); 
    }

    status = stub.getSayHello(exData, ret);
    if (status.code == RpcProcCode.Success) {
        log("sync call getSayHello success :", ret.msg);
        log("sync call getSayHello exData :", status.exData);
    }
    else {
        log("sync call getSayHello failed : ", status.msg); 
    }

    

    //async call
    stub.SayHello(request, exData, (RpcResponseBody response, GreeterResponse r){
        if (response.code == RpcProcCode.Success) {
            log("async call SayHello success :", r.msg);
            log("async call SayHello exData :", response.exData);
        }
        else {
            log("async call SayHello failed : ", response.msg); 
        }
    });
    stub.getSayHello(exData, (RpcResponseBody response, GreeterResponse r){
        if (response.code == RpcProcCode.Success) {
            log("async call getSayHello success :", r.msg);
            log("async call getSayHello exData :", response.exData);
        }
        else {
            log("async call getSayHello failed : ", response.msg); 
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

