module KissRpc.IDL.TestRpcService;


import KissRpc.IDL.TestRpcInterface;
import KissRpc.IDL.TestRpcMessage;

import KissRpc.RpcClient;

class RpcTestService: rpc_test_interface{

	this(RpcClient rpClient){
		super(rpClient);
	}

	UserInfo getName(UserInfo info){

		UserInfo ret = super.getNameInterface(info);
		return ret;
	}


	void getName(UserInfo info, RpcGetNameCallback rpcCallback){

		super.getNameInterface(info, rpcCallback);
	}


}



