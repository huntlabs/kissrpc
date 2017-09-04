import std.stdio;
import core.time;
import std.datetime;

import kissrpc.RpcClient;
import kissrpc.RpcSocketBaseInterface;
import kissrpc.Logs;

import kissrpc.IDL.TestRpcService;
import kissrpc.IDL.TestRpcMessage;

import kissrpc.Unit;



import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.AsynchronousChannelSelector;

import std.conv;

static int testNum = 1000000;
static int atestNum = 1000000;

class ClientSocket : ClientSocketEventInterface
{
	
	this()
	{
		rpClient = new RpcClient(this);
		//rpClient.setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS);
	}
	
	void connectToServer(AsynchronousChannelSelector sel)
	{
		rpClient.connect("0.0.0.0", 4444, sel);
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
			user.name = "helloworld";
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



import kiss.aio.AsynchronousChannelThreadGroup;

void main()
{

	AsynchronousChannelSelector selector = new AsynchronousChannelSelector(10);
    
	ClientSocket client = new ClientSocket;
	client.connectToServer(selector);
	
    selector.start();
    selector.wait();



}
