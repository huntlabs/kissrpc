
module client_test;

import std.stdio;
import KissRpc.rpc_request;
import KissRpc.rpc_client_impl;
import KissRpc.rpc_client;
import KissRpc.unit;
import KissRpc.rpc_response;
import KissRpc.rpc_socket_base_interface;

import std.conv;

static rpc_client rp_client;

class client_socket : client_socket_event_interface
{
	void connectd(rpc_socket_base_interface socket)
	{
		de_writefln("connect to server, %s:%s %s", socket.getIp, socket.getPort, rp_client);
	}
	
	void disconnectd(rpc_socket_base_interface socket)
	{
		de_writefln("client disconnect , %s:%s", socket.getIp, socket.getPort);
		
	}
	
	void write_failed(rpc_socket_base_interface socket)
	{
		de_writefln("client write failed , %s:%s", socket.getIp, socket.getPort);
	}
	
	void read_failed(rpc_socket_base_interface socket)
	{
		de_writefln("client read failed , %s:%s", socket.getIp, socket.getPort);
	}
}


class hello{
	
	this(rpc_client rp_client)
	{
		rp_impl = new rpc_client_impl!(hello)(rp_client);
	}
	
	void say(string s, int i)
	{
		auto req = new rpc_request;
		
		req.push(s, i, 0.1);
		
		rp_impl.async_call(req, delegate(rpc_response resp){
				
				string r_s;
				int r_i;
				double r_d;
				
				resp.pop(r_s,  r_i, r_d);
				writefln("server response:%s, %s, %s", r_s, r_i, r_d);
			});
	}
	
	rpc_client_impl!(hello) rp_impl;
}

unittest
{
	rp_client = new rpc_client(new client_socket);
	rp_client.connect("0.0.0.0", 4444);
	
	
	//	auto hello_client = new hello(rp_client);
	//	
	//	for(int i= 0; i < 3; ++i)
	//	{
	//		hello_client.say("test hello client", i);
	//	}
}