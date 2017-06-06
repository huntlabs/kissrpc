
module server_test;

import std.stdio;
import KissRpc.unit;

import KissRpc.rpc_server;
import KissRpc.rpc_server_impl;
import KissRpc.rpc_response;
import KissRpc.rpc_socket_base_interface;
import KissRpc.rpc_request;

class server_socket : server_socket_event_interface
{
	void listen_failed(const string str)
	{
		de_writeln("server listen failed", str);
	}
	void disconnectd(rpc_socket_base_interface socket)
	{
		de_writeln("client is disconnect");
	}

	void inconming(rpc_socket_base_interface socket)
	{
		de_writefln("client inconming:%s:%s", socket.getIp, socket.getPort);
	}
	
	void write_failed(rpc_socket_base_interface socket)
	{
		de_writefln("write buffer to client is failed, %s:%s", socket.getIp, socket.getPort);
	}
	
	void read_failed(rpc_socket_base_interface socket)
	{
		de_writefln("read buffer from client is failed, %s:%s", socket.getIp, socket.getPort);
	}
}

class hello{
	
	this(rpc_server rp_server)
	{
		rp_impl = new rpc_server_impl!(hello)(rp_server);
		rp_impl.bind_request_callback("say", &this.say);
	}
	
	void say(rpc_request req)
	{
		auto resp = new rpc_response(req);
		
		string r_s;
		int r_i, r_num;
		double r_d;
		
		req.pop(r_s,  r_i, r_d);

		writefln("hello.say:%s, %s, %s, client num:%s", r_s, r_i, r_d, r_num);
		
		resp.push(r_s ~ ":server response", r_num, r_i+1, r_d+0.2);
		rp_impl.response(resp);
	}
	
	rpc_server_impl!(hello) rp_impl;
}


unittest
{
	
	auto rp_server = new rpc_server(new server_socket);
	auto hello_server_test = new hello(rp_server);
	
	rp_server.listen("0.0.0.0", 4444);
	
	
	//auto rp_client = new rpc_client;
	//rp_client.connect("0.0.0.0", 4444);
	
	//auto hello_client_test = new hello_client(rp_client);
	
	//hello_client_test.say("test hello client");
	
}