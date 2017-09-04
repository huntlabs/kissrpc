

module kissrpc.RpcServerListener;

import kissrpc.RpcSocketBaseInterface;
import kissrpc.Logs;

class RpcServerListener : ServerSocketEventInterface
{
    this() {}
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