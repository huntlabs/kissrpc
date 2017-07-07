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

	void asyncCall(RpcRequest req, ReponsCallback callback, string func = __FUNCTION__)
	{
		deWritefln("rpc client imlp call:%s", func);

		req.bindFunc(func);
		client.requestRemoteCall(req);
		client.bindCallback(func, callback);
	}


	RpcResponse syncCall(RpcRequest req, string func = __FUNCTION__)
	{
			deWritefln("rpc client imlp sync call:%s", func);
			
			req.bindFunc(func);
			req.setNonblock(false);
			
			RpcResponse retResp;
					
			void callback(RpcResponse resp)
			{
				retResp = resp;
				req.semaphoreRelease();
			}

			client.bindCallback(func,  &callback);
			client.requestRemoteCall(req);

			req.semaphoreWait();

			return retResp;
	}


private:
	RpcClient client;
}

