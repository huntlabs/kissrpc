import std.stdio;
import KissRpc.rpc_request;
import KissRpc.rpc_client_impl;
import KissRpc.rpc_client;
import KissRpc.unit;
import KissRpc.rpc_response;
import KissRpc.rpc_socket_base_interface;

import std.conv;
import core.thread;

import core.time;
import std.datetime;
import kiss.event.GroupPoll;


static ulong start_clock;

static ulong test_num = 1000000;


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
		
		auto hello_client = new hello(rp_client);
		start_clock = Clock.currStdTime().stdTimeToUnixTime!(long)();
		
		for(int i= 0; i < test_num; ++i)
		{
			hello_client.say("test hello client", i);
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



class hello{
	
	this(rpc_client rp_client)
	{
		rp_impl = new rpc_client_impl!(hello)(rp_client);
	}
	
	int say(string s, int i)
	{
		auto req = new rpc_request;
		
		req.push(s, 1, i, 0.1);
		
		rpc_response resp = rp_impl.sync_call(req);
		
		if(resp.get_status == RESPONSE_STATUS.RS_OK)
		{
			string r_s;
			int r_i, r_num;
			double r_d;
			resp.pop(r_s, r_num, r_i, r_d);

			
			//writefln("server response:%s, %s, %s", r_s, r_i, r_d);
			
			if(r_i % 100000 == 0)
			{
				writefln("single connect test, sync rpc request num:%s, total time:%s", r_i, Clock.currStdTime().stdTimeToUnixTime!(long)()- start_clock);
			}
		}
		
		return 0;
	}
	
	rpc_client_impl!(hello) rp_impl;
}


void main()
{
	import kiss.util.Log;
	load_log_conf("default.conf");
	auto poll = new GroupPoll!();
	
	auto client = new client_socket;
	client.connect_to_server(poll);
	
	poll.start;
	poll.wait;
}