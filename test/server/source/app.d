module app;

import std.stdio;
import std.conv;

import kissrpc.Unit;
import kissrpc.Logs;
import kissrpc.RpcServer;
import kissrpc.RpcSocketBaseInterface;

import kissrpc.RpcRequest;

import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.AsynchronousChannelThreadGroup;

import std.traits;
import std.parallelism;

class ServerSocket : ServerSocketEventInterface
{
	void listenFailed(const string str)
	{
		deWriteln("server listen failed", str);
	}

	void disconnectd(RpcSocketBaseInterface socket)
	{
		deWriteln("client is disconnect");
	}

	shared static int connect_num;
	void inconming(RpcSocketBaseInterface socket)
	{
		logInfo("client inconming:%s:%s, connect num:%s", socket.getIp, socket.getPort, connect_num++);
	}

	void writeFailed(RpcSocketBaseInterface socket)
	{
		deWritefln("write buffer to client is failed, %s:%s", socket.getIp, socket.getPort);
	}

	void readFailed(RpcSocketBaseInterface socket)
	{
		deWritefln("read buffer from client is failed, %s:%s", socket.getIp, socket.getPort);
	}
}



void main(string[] args)
{

	import kissrpc.IDL.TestRpcService;

	int threadNum = totalCPUs;
	// int threadNum = 1;
	AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open(5,threadNum);

	for(int i = 0; i < threadNum; i++)
    {
		auto rpServer = new RpcServer("0.0.0.0", 4444, group,new ServerSocket);
		auto addressBookService = new RpcTestService(rpServer);

    }
	group.start();
	group.wait();
}
