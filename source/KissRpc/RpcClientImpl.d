module KissRpc.RpcClientImpl;

import KissRpc.RpcClient;
import KissRpc.RpcRequest;
import KissRpc.RpcResponse;
import KissRpc.Unit;
import KissRpc.Logs;

import std.stdio;

class RpcClientImpl(T)
{
	this(RpcClient refClient)
	{
		client = refClient;
		foreach(i, func; __traits(derivedMembers, T))
		{
			foreach(t ;__traits(getVirtualMethods, T, func))
			{
				deWritefln("rpc client impl class:%s, member func:%s",typeid(T).toString(), typeid(typeof(t)));
				client.bind(typeid(T).toString(), func);
			}
		}
	}

	void asyncCall(RpcRequest req, ReponsCallback callback, RPC_PACKAGE_PROTOCOL protocol = RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, const size_t funcId = 0)
	{
		deWritefln("rpc client imlp async call:%s, %s", funcId, RpcBindFunctionMap[funcId]);

		req.bindFunc(funcId);
		client.requestRemoteCall(req, protocol);
		client.bindCallback(funcId, callback);
	}


	RpcResponse syncCall(RpcRequest req, RPC_PACKAGE_PROTOCOL protocol = RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, const size_t funcId = 0)
	{
			deWritefln("rpc client imlp sync call:%s, %s", funcId, RpcBindFunctionMap[funcId]);
			
			req.bindFunc(funcId);
			req.setNonblock(false);
			
			RpcResponse retResp;
					
			void callback(RpcResponse resp)
			{
				retResp = resp;
				req.semaphoreRelease();
			}

			client.bindCallback(funcId,  &callback);
			client.requestRemoteCall(req, protocol);

			req.semaphoreWait();

			return retResp;
	}


private:
	RpcClient client;
}

