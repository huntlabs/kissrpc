import std.stdio;
import core.time;
import std.datetime;

import KissRpc.rpc_client;
import KissRpc.rpc_socket_base_interface;
import KissRpc.logs;

import KissRpc.IDL.kiss_idl_service;
import KissRpc.IDL.kiss_idl_message;

import kiss.event.GroupPoll;


static ulong start_clock;

static int test_num = 1;


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

		auto address_book_service = new rpc_address_book_service(rp_client);

		writefln("connect to server, %s:%s", socket.getIp, socket.getPort);

		for(int i= 0; i < test_num; ++i)
		{

			try{

				auto c = address_book_service.get_contact_list("jasonalex");
				foreach(v; c.user_info_list)
				{
					writefln("sync number:%s, name:%s, phone:%s, address list:%s", c.number, v.user_name, v.phone, v.address_list);
					
				}

			}catch(Exception e)
			{
				writeln(e.msg);
			}




			try{

				address_book_service.get_contact_list("jasonsalex", delegate(contacts c){
						
						foreach(v; c.user_info_list)
						{
							writefln("async number:%s, name:%s, phone:%s, address list:%s", c.number, v.user_name, v.phone, v.address_list);
						}
					}
					);
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
}


void main()
{
	import KissRpc.logs;
	auto poll = new GroupPoll!();
	auto client = new client_socket;
	client.connect_to_server(poll);
	
	poll.start;
	poll.wait;
}
