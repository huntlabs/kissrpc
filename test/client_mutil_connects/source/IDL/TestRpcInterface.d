module KissRpc.IDL.TestRpcInterface;

import KissRpc.IDL.TestRpcMessage;
import KissRpc.IDL.TestRpcService;

import KissRpc.RpcRequest;
import KissRpc.RpcClientImpl;
import KissRpc.RpcClient;
import KissRpc.RpcResponse;

abstract class rpc_test_interface{ 

	this(RpcClient rpClient){ 
		rp_impl = new RpcClientImpl!(RpcTestService)(rpClient); 
	}

	UserInfo getNameInterface(UserInfo info, string bindFunc = __FUNCTION__){

		auto req = new RpcRequest;

		req.push(info);

		RpcResponse resp = rp_impl.syncCall(req, bindFunc);

		if(resp.getStatus == RESPONSE_STATUS.RS_OK){
			UserInfo retUserInfo;

			resp.pop(retUserInfo);

			return retUserInfo;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bindFunc);
		}
	}


	alias RpcGetNameCallback = void delegate(UserInfo);

	void getNameInterface(UserInfo info, RpcGetNameCallback rpcCallback, string bindFunc = __FUNCTION__){

		auto req = new RpcRequest;

		req.push(info);

		rp_impl.asyncCall(req, delegate(RpcResponse resp){

			if(resp.getStatus == RESPONSE_STATUS.RS_OK){

				UserInfo retUserInfo;

				resp.pop(retUserInfo);

				rpcCallback(retUserInfo);
			}else{
				throw new Exception("rpc sync call error, function:" ~ bindFunc);
			}}, bindFunc);
	}


	RpcClientImpl!(RpcTestService) rp_impl;
}


