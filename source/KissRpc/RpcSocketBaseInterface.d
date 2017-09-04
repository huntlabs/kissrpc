module kissrpc.RpcSocketBaseInterface;

import std.socket;

interface RpcSocketBaseInterface
{
	bool write(byte[] data);

	int getFd();

	string getIp();

	string getPort();

	void disconnect();
}

interface ClientSocketEventInterface
{
	void connectd(RpcSocketBaseInterface socket);
	void disconnectd(RpcSocketBaseInterface socket);
	void writeFailed(RpcSocketBaseInterface socket);
	void readFailed(RpcSocketBaseInterface socket);
}

interface ServerSocketEventInterface
{
	void listenFailed(const string str);
	void inconming(RpcSocketBaseInterface socket);
	void disconnectd(RpcSocketBaseInterface socket);
	void writeFailed(RpcSocketBaseInterface socket);
	void readFailed(RpcSocketBaseInterface socket);
}
