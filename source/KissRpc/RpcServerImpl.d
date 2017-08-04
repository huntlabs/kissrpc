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

	void bindRequestCallback(const size_t funcId, RequestCallback callback)
	{
		server.bindCallback(funcId, callback);
	}

	void response(RpcResponse resp, RPC_PACKAGE_PROTOCOL protocol = RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF)
	{
		server.RpcResponseRemoteCall(resp, protocol);
	}
	
private:
	RpcServer server;
}

