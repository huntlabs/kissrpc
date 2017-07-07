import std.stdio;
import core.time;
import std.datetime;
import std.stdio;
import core.time;
import std.datetime;

import KissRpc.RpcClient;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Logs;

import KissRpc.IDL.TestRpcService;
import KissRpc.IDL.TestRpcMessage;

import kiss.event.GroupPoll;

import std.conv;

shared static int testNum = 1000;
shared static int clientNum = 1000;

shared static long startAllTime;

class ClientSocket : ClientSocketEventInterface
{
	
	this(int id)
	{
		rpClient = new RpcClient(this);
		clientId = id;
	}
	
	void connectToServer(GroupPoll!() poll)
	{
		rpClient.connect("0.0.0.0", 4444, poll);
	}
	
	void connectd(RpcSocketBaseInterface socket)
	{
		//writefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		RpcTestService service = new RpcTestService(rpClient);

//		writefln("start sync test.......................");
//		for(int i= 1; i <= testNum; ++i)
//		{
//			UserInfo user;
//			user.name = "jasonsalex";
//			user.i = i;
//
//			auto s = service.getName(user);
//
//			if(s.i % 50000 == 0)
//			{
//				writefln("ret:%s, request:%s, time:%s", s, i, Clock.currStdTime().stdTimeToUnixTime!(long)() - start_time);
//			}
//
//		}
//
//
//		writefln("sync test, total request:%s, time:%s, QPS:%s\n\n", testNum, time, testNum/time);
//
//
//
//
//		start_time  = Clock.currStdTime().stdTimeToUnixTime!(long)();

		for(int i= 1; i <= testNum; ++i)
		{
			UserInfo user;
			user.name = "jasonsalex:" ~ to!string(clientId);
			user.i = i;

			try{

				service.getName(user, delegate(UserInfo s){
						
						if(s.i== testNum)
						{
							auto time = (Clock.currStdTime()/10000 - startAllTime)/1000;
							writefln("async test, client id:%s, total request:%s, time:%s", s.name, s.i, time);
						}
						
						
						
						if(s.i == testNum && s.name == "jasonsalex:" ~ to!string(clientNum))
						{
							auto time = (Clock.currStdTime()/10000 - startAllTime)/1000;
							writefln("total async test, total client:%s, total request:%s, time:%s, QPS:%s", s.name, s.i*clientNum, time, testNum*clientNum/time);
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
	int clientId;
}


void main()
{

	auto poll = new GroupPoll!();

	startAllTime = Clock.currStdTime()/10000;

	for(int i = 1; i <= clientNum; ++i)
	{
		auto client = new ClientSocket(i);

		client.connectToServer(poll);
	}


	poll.start;
	poll.wait;
}
