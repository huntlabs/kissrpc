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

import std.typetuple;



struct test_a
{
	int i=1;
	int j=2;
	long f=3;
	long d=4;
	string s = "test_a";

	TypeTuple!(int,int,long,long,string) member_list;

	
	void create_type_tulple()
	{
		member_list[0] = i;
		member_list[1] = j;
		member_list[2] = f;
		member_list[3] = d;
		member_list[4] = s;
	}


	void restore_type_tunlp()
	{
		i = member_list[0];
		j = member_list[1];
		f = member_list[2];
		d = member_list[3];
		s = member_list[4];
	}
}

struct test
{
	int i=1;
	int j=2;
	long f=3;
	long d=4;
	string s = "test";
	test_a[] a_test;
	TypeTuple!(int, int, long, long, string, test_a[]) member_list;


	void create_type_tulple()
	{
		member_list[0] = i;
		member_list[1] = j;
		member_list[2] = f;
		member_list[3] = d;
		member_list[4] = s;
		member_list[5] = a_test;
	}

	void restore_type_tunlp()
	{
		i = member_list[0];
		j = member_list[1];
		f = member_list[2];
		d = member_list[3];
		s = member_list[4];
		a_test = member_list[5];
	}

}

class fal
{
	this()
	{
	 //writefln("####################:%s",isAggregateType!(T));
	}

	bool get(T...)(T args)
	{
		return isAggregateType!(T[0]);
	}
}


void main(string[] args)
{

	test t;
	rpc_request req = new rpc_request;
	t.i = 100;
	t.f =1233;
	t.s = "$$$$$$$$$$$$";
	t.a_test = new test_a[2];
	t.a_test[0].s = "**************************";

	req.push(t);

	test b;

	req.pop(b);

	writeln(b.s);
	foreach(i; b.a_test)
	{
		writefln(i.s);
	}




//	auto rp_server = new rpc_server(new server_socket);
//	auto hello_service = new rpc_hello_service(rp_server);
//
//	auto poll = new GroupPoll!();
//
//	if(rp_server.listen("0.0.0.0", 4444, poll))
//	{
//		log_info("start server is ok");
//	}
//
//	poll.start();
//	poll.wait();
}