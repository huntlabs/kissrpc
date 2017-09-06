

module kissrpc.RpcClientListener;

import kissrpc.RpcSocketBaseInterface;
import kissrpc.Logs;
import kiss.aio.AsynchronousChannelSelector;
import kissrpc.RpcClient;

import std.stdio;


class RpcClientListener : ClientSocketEventInterface
{
	
	this(string ip, ushort port, AsynchronousChannelSelector sel)
	{
		_rpClient = new RpcClient(this);
        _rpClient.connect(ip, port, sel);
	}

	void connectd(RpcSocketBaseInterface socket)
	{

	}

	void reConnect() 
	{
		_rpClient.reConnect();
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
	
public:
	RpcClient _rpClient;
}
