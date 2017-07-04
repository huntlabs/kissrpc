module KissRpc.rpc_server_impl;

import KissRpc.rpc_server;
import KissRpc.rpc_response;
import KissRpc.unit;
import KissRpc.logs;

class rpc_server_impl(T)
{
	this(rpc_server ref_server)
	{
		server = ref_server;

		foreach(i, func_name; __traits(derivedMembers, T))
		{
			foreach(call_back ;__traits(getVirtualMethods, T, func_name))
			{
				de_writefln("rpc server impl class:%s, member func:%s",typeid(T).toString(), typeid(typeof(call_back)));
				server.bind(typeid(T).toString(), func_name);
			}
		}
	}

	void bind_request_callback(string func_name, request_callback call_back)
	{
		server.bind_callback(typeid(T).toString()~"."~func_name, call_back);
	}
	
	void response(rpc_response resp)
	{
		server.rpc_response_remote_call(resp);
	}
	
private:
	rpc_server server;
}

