module KissRpc.RpcClientSocket;

import KissRpc.RpcRecvPackageManage;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Unit;
import KissRpc.Logs;

// import kiss.aio.AsyncTcpBase;
// import kiss.event.Poll;
// import kiss.time.Timer;
// import kiss.aio.AsyncTcpClient;

import std.stdio;
import std.socket;
import std.conv;

import core.thread;


import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.ByteBuffer;
import kiss.net.TcpClient;

class RpcClientSocket: TcpClient, RpcSocketBaseInterface
{
public:
	this(string ip, ushort port, AsynchronousChannelSelector sel, RpcEventInterface rpcEventDelegate) {
		super(ip, port, sel, RPC_PACKAGE_MAX);
		_packageManage = new RpcRecvPackageManage(this, rpcEventDelegate);
		_socketEventDelegate = rpcEventDelegate;
	}
	bool write(byte[] buf) {
		// writeln("write index ",index++);
		super.doWrite(buf);
		return true;
	}
	override void onConnectCompleted(void* attachment) {
		doRead();
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_CONNECTD, "connect to server is ok!");
	}
    override void onConnectFailed(void* attachment) {
		writeln("onConnectFailed");
	}
    override void onWriteCompleted(void* attachment, size_t count , ByteBuffer buffer) {
		// writeln("write success index ",index);
	}
	override void onWriteFailed(void* attachment) {
		writeln("onWriteFailed");
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_WRITE_FAILED, "write data to server is failed");
	}
    override void onReadCompleted(void* attachment, size_t count , ByteBuffer buffer) {

		_packageManage.add(cast(ubyte[])(buffer.getCurBuffer()));
		_readBuffer.clear();
	}
	override void onReadFailed(void* attachment) {
		writeln("onReadFailed");
	}
	override void onClose() {
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from server!");
	}
	void disconnect()
	{
		close();	
	}
	int getFd() { return cast(int)(fd()); }
	string getIp() { return ip(); }
	string getPort() { return port(); }


private:
	RpcEventInterface _socketEventDelegate;
	RpcRecvPackageManage _packageManage;
	long index = 1;
}

