module KissRpc.IDL.TestRpcService;

import KissRpc.IDL.TestRpcInterface;
import KissRpc.IDL.TestRpcMessage;

import KissRpc.RpcServer;
import KissRpc.Logs;

class RpcTestService: RpcTestInterface{

	this(RpcServer rpServer){
		super(rpServer);
	}

	UserInfo getName(UserInfo info){

		UserInfo userInfoRet = info;

		deWritefln("getName:%s, %s",info.i,info.name);
		return userInfoRet;
	}



}



