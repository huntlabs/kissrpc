module KissRpc.IDL.TestRpcService;

import KissRpc.IDL.TestRpcInterface;
import KissRpc.IDL.TestRpcMessage;

import KissRpc.RpcServer;

class RpcTestService: RpcTestInterface{

	this(RpcServer rpServer){
		super(rpServer);
	}

	UserInfo getName(UserInfo info){

		UserInfo userInfoRet = info;


		return userInfoRet;
	}



}



