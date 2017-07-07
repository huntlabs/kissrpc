
import std.stdio;
import KissRpc.RpcRequest;
import KissRpc.RpcClientImpl;
import KissRpc.RpcClient;
import KissRpc.Unit;
import KissRpc.RpcResponse;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Logs;

import std.conv;
import core.thread;

import core.time;
import std.datetime;
import kiss.event.GroupPoll;

static ulong startClock;

static ulong testNum = 1000;
static ulong testClient = 1000;

class ClientSocket : ClientSocketEventInterface
{
	this(const int num)
	{
		clientNum = num;
		rpClient = new RpcClient(this);
		hello.startClock = Clock.currStdTime().stdTimeToUnixTime!(long)();
		
	}
	
	void connectToServer(GroupPoll!() poll)
	{
		rpClient.connect("0.0.0.0", 4444, poll);
	}
	
	void connectd(RpcSocketBaseInterface socket)
	{
		//deWritefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		
		auto hello_client = new hello(rpClient);
		
		for(int i= 0; i < testNum; ++i)
		{
			hello_client.say("test hello client", i, clientNum);
		}
		
	}
	
	void disconnectd(RpcSocketBaseInterface socket)
	{
		deWritefln("client disconnect ....");
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
	int clientNum;
	RpcClient rpClient;
}



class hello{
	
	this(RpcClient rpClient)
	{
		rpImpl = new RpcClientImpl!(hello)(rpClient);
	}
	
	void say(string s, int i, int num)
	{
		auto req = new RpcRequest;
		
		req.push(s, num, i, 0.1);

		rpImpl.asyncCall(req, delegate(RpcResponse resp){
				
				if(resp.getStatus == RESPONSE_STATUS.RS_OK)
				{
					string r_s;
					int r_i, r_num;
					double r_d;
					
					resp.pop(r_s,  r_num, r_i, r_d);
					//writefln("server response:%s, %s, %s", r_s, r_i, r_d);
					
					if(r_i == testNum)
					{
						if(finishNum++)
						{
							writefln("%s connect test, client num:%s, rpc request num:%s, total time:%s", finishNum, r_num, r_i, Clock.currStdTime().stdTimeToUnixTime!(long)()- startClock);
						}
					}
				}else
				{
					writeln("error:", resp.getStatus);
				}
			});
		
	}
	
	shared static uint finishNum;
	shared static ulong startClock;
	RpcClientImpl!(hello) rpImpl;
}

void main()
{


	auto poll = new GroupPoll!();
	
	
	for(int i= 0; i< testClient; i++)
	{
		auto client = new ClientSocket(i);
		client.connectToServer(poll);
	}
	
	poll.start;
	poll.wait;
}
