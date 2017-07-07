module KissRpc.IDL.TestRpcInterface;

import KissRpc.IDL.TestRpcMessage;
import KissRpc.IDL.TestRpcService;

import KissRpc.RpcServer;
import KissRpc.RpcServerImpl;
import KissRpc.RpcResponse;
import KissRpc.RpcRequest;
abstract class RpcTestInterface{ 

	this(RpcServer rpServer){ 
		rpImpl = new RpcServerImpl!(RpcTestService)(rpServer); 
		rpImpl.bindRequestCallback("getName", &this.getNameInterface); 

	}

	void getNameInterface(RpcRequest req){

		auto resp = new RpcResponse(req);

		UserInfo info;


		req.pop(info);

		UserInfo retUserInfo;

		retUserInfo = (cast(RpcTestService)this).getName(info);

		resp.push(retUserInfo);

		rpImpl.response(resp);
	}



	RpcServerImpl!(RpcTestService) rpImpl;
}


