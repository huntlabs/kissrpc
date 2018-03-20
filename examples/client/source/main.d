


import kissrpc;

import rpcgenerate.Greeter;


import std.string;
import core.thread;


void doClientTest(RpcClient client) {
    GreeterStub stub = new GreeterStub(client);
    RpcResponseBody response;
    Monster monsterResult;
    ubyte[] exData = cast(ubyte[])("hello kissrpc");

    Monster monster;
    monster.id = 1;
    monster.pos.x = 0;
    monster.pos.y = 0;
    monster.pos.z = 0;

    
    log("--------------------start sync call--------------------");
    response = stub.updateAndGetMonster(monster, monsterResult, exData);
    if (response.code == RpcProcCode.Success) {
        log("sync monsterResult = ", monsterResult);
    }
    
    response = stub.getFirstMonster(monsterResult, exData);
    if (response.code == RpcProcCode.Success) {
        log("sync getFirstMonster = ", monsterResult);
    }

    response = stub.updateMonster(monster, exData);
    if (response.code == RpcProcCode.Success) {
        log("sync updateMonster");
    }

    response = stub.removeAllMonster(exData);
    if (response.code == RpcProcCode.Success) {
        log("sync removeAllMonster");
    }

    log("--------------------start async call--------------------");
    stub.updateAndGetMonster(monster, exData, (RpcResponseBody res, Monster ret){
        if (res.code == RpcProcCode.Success) {
            log("async updateAndGetMonster", ret);
        }}
    );
    stub.getFirstMonster(exData, (RpcResponseBody res, Monster ret){
        if (res.code == RpcProcCode.Success) {
            log("async getFirstMonster", ret);
        }}
    );
    stub.updateMonster(monster, exData, (RpcResponseBody res){
        if (res.code == RpcProcCode.Success) {
            log("async updateMonster");
        }}
    );
    stub.removeAllMonster(exData, (RpcResponseBody res){
        if (res.code == RpcProcCode.Success) {
            log("async removeAllMonster");
        }}
    );
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

