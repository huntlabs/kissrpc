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

shared static int test_num = 1000;
shared static int client_num = 1000;

shared static long start_all_time;

class client_socket : client_socket_event_interface
{
	
	this(int id)
	{
		rp_client = new rpc_client(this);
		client_id = id;
	}
	
	void connect_to_server(GroupPoll!() poll)
	{
		rp_client.connect("0.0.0.0", 4444, poll);
	}
	
	void connectd(rpc_socket_base_interface socket)
	{
		//writefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		rpc_test_service service = new rpc_test_service(rp_client);

//		writefln("start sync test.......................");
//		for(int i= 1; i <= test_num; ++i)
//		{
//			user_info user;
//			user.name = "jasonsalex";
//			user.i = i;
//
//			auto s = service.get_name(user);
//
//			if(s.i % 50000 == 0)
//			{
//				writefln("ret:%s, request:%s, time:%s", s, i, Clock.currStdTime().stdTimeToUnixTime!(long)() - start_time);
//			}
//
//		}
//
//
//		writefln("sync test, total request:%s, time:%s, QPS:%s\n\n", test_num, time, test_num/time);
//
//
//
//
//		start_time  = Clock.currStdTime().stdTimeToUnixTime!(long)();

		for(int i= 1; i <= test_num; ++i)
		{
			user_info user;
			user.name = "jasonsalex:" ~ to!string(client_id);
			user.i = i;

			try{

				service.get_name(user, delegate(user_info s){
						
						if(s.i== test_num)
						{
							auto time = (Clock.currStdTime()/10000 - start_all_time)/1000;
							writefln("async test, client id:%s, total request:%s, time:%s", s.name, s.i, time);
						}
						
						
						
						if(s.i == test_num && s.name == "jasonsalex:" ~ to!string(client_num))
						{
							auto time = (Clock.currStdTime()/10000 - start_all_time)/1000;
							writefln("total async test, total client:%s, total request:%s, time:%s, QPS:%s", s.name, s.i*client_num, time, test_num*client_num/time);
						}
						
					});
			}catch(Exception e)
			{
				writeln(e.msg);
			}

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
	int client_id;
}


void main()
{

	auto poll = new GroupPoll!();

	start_all_time = Clock.currStdTime()/10000;

	for(int i = 1; i <= client_num; ++i)
	{
		auto client = new client_socket(i);

		client.connect_to_server(poll);
	}


	poll.start;
	poll.wait;
}
