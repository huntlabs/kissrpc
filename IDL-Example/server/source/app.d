module app;

import std.stdio;
import std.conv;

import kissrpc.Unit;
import kissrpc.Logs;
import kissrpc.RpcServer;
import kissrpc.RpcSocketBaseInterface;

import kiss.event.GroupPoll;
import std.traits;


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

	import kissrpc.IDL.kissidlService;

	auto rpServer = new RpcServer(new ServerSocket);
	auto address_book_service = new RpcAddressBookService(rpServer);


	auto poll = new GroupPoll!();

	if(rpServer.listen("0.0.0.0", 4444, poll))
	{
		logInfo("start server is ok");
	}

	poll.start();
	poll.wait();
}
