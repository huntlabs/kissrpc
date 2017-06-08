module KissRpc.rpc_client_impl;

import KissRpc.rpc_client;
import KissRpc.rpc_request;
import KissRpc.rpc_response;
import std.stdio;
import KissRpc.unit;
import KissRpc.logs;

class rpc_client_impl(T)
{
	this(rpc_client ref_client)
	{
		client = ref_client;
		foreach(i, func; __traits(derivedMembers, T))
		{
			foreach(t ;__traits(getVirtualMethods, T, func))
			{
				de_writefln("rpc client impl class:%s, member func:%s",typeid(T).toString(), typeid(typeof(t)));
				client.bind(typeid(T).toString(), func);
			}
		}
	}

	void async_call(rpc_request req, repons_callback call_back, string func = __FUNCTION__)
	{
		de_writefln("rpc client imlp call:%s", func);

		req.bind_func(func);
		client.request_remote_call(req);
		client.bind_callback(func, call_back);
	}


	rpc_response sync_call(rpc_request req, string func = __FUNCTION__)
	{
			de_writefln("rpc client imlp sync call:%s", func);
			
			req.bind_func(func);
			req.set_nonblock(false);
			
			rpc_response ret_resp;
					
			void callback(rpc_response resp)
			{
				ret_resp = resp;
				req.semaphore_release();
			}

			client.bind_callback(func,  &callback);
			client.request_remote_call(req);

			req.semaphore_wait();

			return ret_resp;
	}


private:
	rpc_client client;
}

