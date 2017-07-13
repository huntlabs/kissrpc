import std.stdio;
import core.time;
import std.datetime;

import KissRpc.RpcClient;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Logs;

import KissRpc.IDL.KissIdlService;
import KissRpc.IDL.KissIdlMessage;

import kiss.event.GroupPoll;
import KissRpc.Unit;

static ulong startClock;

static int testNum = 1;


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

			try{
				writeln("----------------------------------------------------------------------");
				auto c = addressBookService.getContactList("jasonalex");
				foreach(v; c.userInfoList)
				{
					writefln("sync number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
					
				}

			}catch(Exception e)
			{
				writeln(e.msg);
			}


			try{

				addressBookService.getContactList("jasonsalex", delegate(contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("async number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
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
				auto c = addressBookService.getContactList("jasonalex", RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS);
				foreach(v; c.userInfoList)
				{
					writefln("compress test: sync number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
					
				}
				
			}catch(Exception e)
			{
				writeln(e.msg);
			}

			//use dynamic compress and set request timeout


			try{
				RPC_PACKAGE_COMPRESS_DYNAMIC_VALUE = 100; //reset compress dynamaic value 100 byte, default:200 byte

				addressBookService.getContactList("jasonsalex", delegate(contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("dynamic compress test: async number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
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
	import KissRpc.Logs;
	auto poll = new GroupPoll!();
	auto client = new ClientSocket;
	client.connectToServer(poll);
	
	poll.start;
	poll.wait;
}
