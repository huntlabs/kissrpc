

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

void main() {
    RpcServer server = RpcManager.getInstance().createRpcServer("0.0.0.0", 9000, (RpcStream stream, RpcEvent code, string msg){
        log("<-----------server event code = %s, msg = %s".format(code,msg));
    });
}

