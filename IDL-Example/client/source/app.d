import std.stdio;
import core.time;
import std.datetime;

import kissrpc.RpcClient;
import kissrpc.RpcSocketBaseInterface;
import kissrpc.Logs;

import kissrpc.IDL.kissidlService;
import kissrpc.IDL.kissidlMessage;

import kiss.event.GroupPoll;
import kissrpc.Unit;

import std.conv;

static ulong startClock;

static int testNum = 1000;


class ClientSocket : ClientSocketEventInterface
{
	
	this()
	{
		rpClient = new RpcClient(this);
		// rpClient.setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC); //bind socket compress
	}
	
	void connectToServer(GroupPoll!() poll)
	{
		rpClient.connect("0.0.0.0", 4444, poll);
	}

	
	void connectd(RpcSocketBaseInterface socket)
	{

		auto addressBookService = new RpcAddressBookService(rpClient);

		writefln("connect to server, %s:%s", socket.getIp, socket.getPort);

		for(int i= 0; i < testNum; ++i)
		{
			AccountName name;
			name.name = "jasonsalex";
			name.count = i;

			try{
				writeln("----------------------------------------------------------------------");
				auto c = addressBookService.getContactList(name);
				foreach(v; c.userInfoList)
				{
					writefln("sync number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
					
				}

			}catch(Exception e)
			{
				writeln(e.msg);
			}


			try{

				addressBookService.getContactList(name, delegate(Contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("async number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
						}
					}
				);
			}catch(Exception e)
			{
				writeln(e.msg);
			}

			//use compress demo
			try{
				writeln("-------------------------user request compress---------------------------------------------");
				auto c = addressBookService.getContactList(name, RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS);

				foreach(v; c.userInfoList)
				{
					writefln("compress test: sync number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
				}
				
			}catch(Exception e)
			{
				writeln(e.msg);
			}

			//use dynamic compress and set request timeout


			try{
				RPC_PACKAGE_COMPRESS_DYNAMIC_VALUE = 100; //reset compress dynamaic value 100 byte, default:200 byte

				addressBookService.getContactList(name, delegate(Contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("dynamic compress test: sync number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
						}

					}, RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC, 30
				);

			}catch(Exception e)
			{
				writeln(e.msg);
			}
		}
	}

	
	void disconnectd(RpcSocketBaseInterface socket)
	{
		writefln("client disconnect ....");
	}
	
	void writeFailed(RpcSocketBaseInterface socket)
	{
		deWritefln("client write failed , %s:%s", socket.getIp, socket.getPort);
	}
	
	void readFailed(RpcSocketBaseInterface socket)
	{
		deWritefln("client read failed , %s:%s", socket.getIp, socket.getPort);
	}
	
private:
	
	RpcClient rpClient;
}


void main()
{
	import kissrpc.Logs;
	auto poll = new GroupPoll!();
	auto client = new ClientSocket;
	client.connectToServer(poll);
	
	poll.start;
	poll.wait;
}
