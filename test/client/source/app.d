import std.stdio;
import core.time;
import std.datetime;

import KissRpc.RpcClient;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Logs;

import KissRpc.IDL.TestRpcService;
import KissRpc.IDL.TestRpcMessage;

import kiss.event.GroupPoll;
import KissRpc.Unit;

import std.conv;

static int testNum = 300000;
static int atestNum = 300000;

class ClientSocket : ClientSocketEventInterface
{
	
	this()
	{
		rpClient = new RpcClient(this);
		//rpClient.setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS);
	}
	
	void connectToServer(GroupPoll!() poll)
	{
		rpClient.connect("0.0.0.0", 4444, poll);
	}
	
	void connectd(RpcSocketBaseInterface socket)
	{
		writefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		RpcTestService service = new RpcTestService(rpClient);

		auto startTime  = Clock.currStdTime().stdTimeToUnixTime!(long)();



		writefln("start sync test.......................");
		for(int i= 1; i <= testNum; ++i)
		{
			UserInfo user;
			user.name = "jasonsalex";
			user.i = i;

			try{
				auto s = service.getName(user);
				
				if(s.i % 50000 == 0)
				{
					writefln("ret:%s, request:%s, time:%s", s, i, Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime);
				}
			}catch(Exception e)
			{
				writeln(e.msg);
			}


		}

		auto time = Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime;

		writefln("sync test, total request:%s, time:%s, QPS:%s\n\n", testNum, time, testNum/time);




		startTime  = Clock.currStdTime().stdTimeToUnixTime!(long)();

		writefln("start async test.......................");

		for(int i= 1; i <= atestNum; ++i)
		{
			UserInfo user;
			user.name = "jasonaslex";
			user.i = i;
				
			try{
				service.getName(user, delegate(UserInfo s){
						
						if(s.i%50000 == 0)
						{
							writefln("ret:%s, request:%s, time:%s", s, s.i, Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime);
						}
						
						if(s.i == atestNum)
						{
							time = Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime;
							writefln("async test, total request:%s, time:%s, QPS:%s", s.i, time, atestNum/time);
						}
						
					});
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

	auto poll = new GroupPoll!();
	auto client = new ClientSocket;
	client.connectToServer(poll);
	
	poll.start;
	poll.wait;
}
