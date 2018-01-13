

import std.stdio;
import rpc.Greeter;
import kissrpc.RpcBuild;
import kissrpc.RpcManager;
import kissrpc.RpcClient;
import kissrpc.RpcConstant;

import kissrpc.RpcServer;
import kissrpc.RpcClient;
import kissrpc.RpcStream;

import core.thread;
import std.traits;
import std.experimental.logger.core;
import std.string;

import example.GreeterMessage;
import example.GreeterRequestFb;
import example.GreeterResponseFb;

import kiss.exception;
import kiss.net.struct_;
import kiss.event.loop;
import kiss.net.TcpStreamClient;


final class GreeterService : Greeter {
    mixin MakeRpc;
public:
    @RpcAction
    override GreeterResponse SayHello(GreeterRequest message) {
        GreeterResponse msg;
        msg.msg = message.msg;
        return msg;
    }
}


void clientConnectCb(RpcClient client) {
    GreeterStub stub = new GreeterStub(client);
    GreeterResponse ret;
    GreeterRequest request;
    request.msg = "hello";

    //sync call
    RpcResponseBody status = stub.SayHello(request, ret);
    if (status.code == RpcProcCode.Success) {
        writeln("call success ", ret.msg);
    }
    else {
        writeln("call failed : ", status.msg); 
    }

    //async call
    stub.SayHello(request,(RpcResponseBody response, GreeterResponse r){
        if (response.code == RpcProcCode.Success) {
            writeln("call success ", response.msg);
            writeln("recv r = ",r.msg);
        }
        else {
            writeln("call failed : ", response.msg); 
        }
    });
}


void main() {

    RpcServer server = RpcManager.getInstance().createRpcServer("0.0.0.0",9000, (RpcStream stream, RpcEvent code, string msg){
        log("<-----------server event code = %s, msg = %s".format(code,msg));
    });
    RpcClient client = RpcManager.getInstance().createRpcClient("0.0.0.0",cast(ushort)9000, &clientConnectCb, (RpcStream stream, RpcEvent code, string msg){
        log("<-----------client event code = %s, msg = %s".format(code,msg));
    });
    
    new Thread({
        server.start();
    }).start();

    Thread.sleep(1000.msecs);
    client.connect();
    client.start();
}

