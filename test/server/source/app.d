module app;

import std.stdio;
import std.conv;

import KissRpc.unit;
import KissRpc.logs;
import KissRpc.rpc_server;
import KissRpc.rpc_socket_base_interface;

import KissRpc.rpc_request;

import kiss.event.GroupPoll;
import std.traits;


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

	shared static int connect_num;
	void inconming(rpc_socket_base_interface socket)
	{
		log_info("client inconming:%s:%s, connect num:%s", socket.getIp, socket.getPort, connect_num++);
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



void main(string[] args)
{

	import KissRpc.IDL.test_rpc_service;

	auto rp_server = new rpc_server(new server_socket);
	auto address_book_service = new rpc_test_service(rp_server);

	auto poll = new GroupPoll!();

	if(rp_server.listen("0.0.0.0", 4444, poll))
	{
		log_info("start server is ok");
	}

	poll.start();
	poll.wait();
}
