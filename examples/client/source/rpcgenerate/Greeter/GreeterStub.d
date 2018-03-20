// automatically generated, do not modify
module rpcgenerate.Greeter.GreeterStub;

import rpcgenerate.Greeter.GreeterBase;
import kissrpc.RpcConstant;
import kissrpc.RpcClient;

final class GreeterStub {
public:
	this(RpcClient client) {
		_rpcClient = client;
	}
	RpcResponseBody updateAndGetMonster(Monster monster, ref Monster ret, ubyte[] exData) {
		RpcResponseBody response;
		ret = _rpcClient.call!(Monster, Monster)("Greeter.updateAndGetMonster", response, exData, monster);
		return response;
	}
	RpcResponseBody getFirstMonster(ref Monster ret, ubyte[] exData) {
		RpcResponseBody response;
		ret = _rpcClient.call!(Monster)("Greeter.getFirstMonster", response, exData);
		return response;
	}
	RpcResponseBody updateMonster(Monster monster, ubyte[] exData) {
		RpcResponseBody response;
		_rpcClient.call!(void, Monster)("Greeter.updateMonster", response, exData, monster);
		return response;
	}
	RpcResponseBody removeAllMonster(ubyte[] exData) {
		RpcResponseBody response;
		_rpcClient.call!()("Greeter.removeAllMonster", response, exData);
		return response;
	}
	void updateAndGetMonster(Monster monster, ubyte[] exData, void delegate(RpcResponseBody response, Monster ret) func) {
		_rpcClient.call!(Monster, Monster)("Greeter.updateAndGetMonster", exData, (RpcResponseBody response, Monster ret){
			func(response, ret);
		}, monster);
	}
	void getFirstMonster(ubyte[] exData, void delegate(RpcResponseBody response, Monster ret) func) {
		_rpcClient.call!(Monster)("Greeter.getFirstMonster", exData, (RpcResponseBody response, Monster ret){
			func(response, ret);
		});
	}
	void updateMonster(Monster monster, ubyte[] exData, void delegate(RpcResponseBody response) func) {
		_rpcClient.call!(Monster)("Greeter.updateMonster", exData, (RpcResponseBody response){
			func(response);
		}, monster);
	}
	void removeAllMonster(ubyte[] exData, void delegate(RpcResponseBody response) func) {
		_rpcClient.call!()("Greeter.removeAllMonster", exData, (RpcResponseBody response){
			func(response);
		});
	}
private:
	RpcClient _rpcClient;
}
