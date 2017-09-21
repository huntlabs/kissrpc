

module kissrpc.RpcServerListener;

import kissrpc.RpcSocketBaseInterface;
import kissrpc.Logs;

class RpcServerListener : ServerSocketEventInterface
{
    this() {}
	void listenFailed(const string str)
	{
		logInfo("server listen failed", str);
	}

	void disconnectd(RpcSocketBaseInterface socket)
	{
		logInfo("client is disconnect");
	}

	shared static int connect_num;
	void inconming(RpcSocketBaseInterface socket)
	{
		logInfo("client inconming:%s:%s, connect num:%s", socket.getIp, socket.getPort, connect_num++);
	}

	void writeFailed(RpcSocketBaseInterface socket)
	{
		logInfo("write buffer to client is failed, %s:%s", socket.getIp, socket.getPort);
	}

	void readFailed(RpcSocketBaseInterface socket)
	{
		logInfo("read buffer from client is failed, %s:%s", socket.getIp, socket.getPort);
	}
}