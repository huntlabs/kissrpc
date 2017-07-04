import std.stdio;
import core.time;
import std.datetime;

import KissRpc.rpc_client;
import KissRpc.rpc_socket_base_interface;
import KissRpc.logs;

import KissRpc.IDL.test_rpc_service;
import KissRpc.IDL.test_rpc_message;

import kiss.event.GroupPoll;

import std.conv;

static int test_num = 500000;


class client_socket : client_socket_event_interface
{
	
	this()
	{
		rp_client = new rpc_client(this);
	}
	
	void connect_to_server(GroupPoll!() poll)
	{
		rp_client.connect("0.0.0.0", 4444, poll);
	}
	
	void connectd(rpc_socket_base_interface socket)
	{
		writefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		rpc_test_service service = new rpc_test_service(rp_client);

		auto start_time  = Clock.currStdTime().stdTimeToUnixTime!(long)();



		writefln("start sync test.......................");
		for(int i= 1; i <= test_num; ++i)
		{
			user_info user;
			user.name = "jasonsalex";
			user.i = i;

			auto s = service.get_name(user);

			if(s.i % 50000 == 0)
			{
				writefln("ret:%s, request:%s, time:%s", s, i, Clock.currStdTime().stdTimeToUnixTime!(long)() - start_time);
			}

		}

		auto time = Clock.currStdTime().stdTimeToUnixTime!(long)() - start_time;

		writefln("sync test, total request:%s, time:%s, QPS:%s\n\n", test_num, time, test_num/time);




		start_time  = Clock.currStdTime().stdTimeToUnixTime!(long)();

		writefln("start async test.......................");

		for(int i= 1; i <= test_num; ++i)
		{
			user_info user;
			user.name = "jasonsalex";
			user.i = i;

					service.get_name(user, delegate(user_info s){
						
							if(s.i%50000 == 0)
							{
								writefln("ret:%s, request:%s, time:%s", s, s.i, Clock.currStdTime().stdTimeToUnixTime!(long)() - start_time);
							}

							if(s.i == test_num)
							{
								time = Clock.currStdTime().stdTimeToUnixTime!(long)() - start_time;
								writefln("async test, total request:%s, time:%s, QPS:%s", s.i, time, test_num/time);
							}
							
						});

		}

	}
	
	void disconnectd(rpc_socket_base_interface socket)
	{
		writefln("client disconnect ....");
	}
	
	void write_failed(rpc_socket_base_interface socket)
	{
		de_writefln("client write failed , %s:%s", socket.getIp, socket.getPort);
	}
	
	void read_failed(rpc_socket_base_interface socket)
	{
		de_writefln("client read failed , %s:%s", socket.getIp, socket.getPort);
	}
	
private:
	
	rpc_client rp_client;
}


void main()
{

	auto poll = new GroupPoll!();
	auto client = new client_socket;
	client.connect_to_server(poll);
	
	poll.start;
	poll.wait;
}
