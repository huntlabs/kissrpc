
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

static ulong test_num = 1000;
static ulong test_client = 1000;

class client_socket : client_socket_event_interface
{
	this(const int num)
	{
		client_num = num;
		rp_client = new rpc_client(this);
		hello.start_clock = Clock.currStdTime().stdTimeToUnixTime!(long)();
		
	}
	
	void connect_to_server(GroupPoll!() poll)
	{
		rp_client.connect("0.0.0.0", 4444, poll);
	}
	
	void connectd(rpc_socket_base_interface socket)
	{
		//de_writefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		
		auto hello_client = new hello(rp_client);
		
		for(int i= 0; i < test_num; ++i)
		{
			hello_client.say("test hello client", i, client_num);
		}
		
	}
	
	void disconnectd(rpc_socket_base_interface socket)
	{
		de_writefln("client disconnect ....");
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
	int client_num;
	rpc_client rp_client;
}



class hello{
	
	this(rpc_client rp_client)
	{
		rp_impl = new rpc_client_impl!(hello)(rp_client);
	}
	
	void say(string s, int i, int num)
	{
		auto req = new rpc_request;
		
		req.push(s, num, i, 0.1);

		rp_impl.async_call(req, delegate(rpc_response resp){
				
				if(resp.get_status == RESPONSE_STATUS.RS_OK)
				{
					string r_s;
					int r_i, r_num;
					double r_d;
					
					resp.pop(r_s,  r_num, r_i, r_d);
					//writefln("server response:%s, %s, %s", r_s, r_i, r_d);
					
					if(r_i == test_num)
					{
						if(finish_num++)
						{
							writefln("%s connect test, client num:%s, rpc request num:%s, total time:%s", finish_num, r_num, r_i, Clock.currStdTime().stdTimeToUnixTime!(long)()- start_clock);
						}
					}
				}else
				{
					writeln("error:", resp.get_status);
				}
			});
		
	}
	
	shared static uint finish_num;
	shared static ulong start_clock;
	rpc_client_impl!(hello) rp_impl;
}

void main()
{

	import kiss.util.Log;
	load_log_conf("default.conf");
	auto poll = new GroupPoll!();
	
	
	for(int i= 0; i< test_client; i++)
	{
		auto client = new client_socket(i);
		client.connect_to_server(poll);
	}
	
	poll.start;
	poll.wait;
}
