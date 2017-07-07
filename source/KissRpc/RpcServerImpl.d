module KissRpc.RpcServerImpl;

import KissRpc.RpcServer;
import KissRpc.RpcResponse;
import KissRpc.Unit;
import KissRpc.Logs;

class RpcServerImpl(T)
{
	this(RpcServer ref_server)
	{
		server = ref_server;

		foreach(i, funcName; __traits(derivedMembers, T))
		{
			foreach(callback ;__traits(getVirtualMethods, T, funcName))
			{
				deWritefln("rpc server impl class:%s, member func:%s",typeid(T).toString(), typeid(typeof(callback)));
				server.bind(typeid(T).toString(), funcName);
			}
		}
	}

	void bindRequestCallback(string funcName, RequestCallback callback)
	{
		server.bindCallback(typeid(T).toString()~"."~funcName, callback);
	}
	
	void response(RpcResponse resp)
	{
		server.RpcResponseRemoteCall(resp);
	}
	
private:
	RpcServer server;
}

