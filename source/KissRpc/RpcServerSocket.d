module KissRpc.RpcServerSocket;

import KissRpc.RpcRecvPackageManage;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Unit;

import std.socket;
import std.stdio;
import std.conv;
import core.thread;

import kiss.aio.AsyncTcpBase;
import kiss.event.Poll;

class RpcServerSocket:AsyncTcpBase, RpcSocketBaseInterface{

public:
	this(Poll poll, RpcEventInterface rpcEventDalegate)
	{
		readBuff = new byte[RPC_PACKAGE_MAX];

		_socketEventDelegate = rpcEventDalegate;
		_packageManage = new RpcRecvPackageManage(this, rpcEventDalegate);

		super(poll);
	}

	~this()
	{
		
	}

	override  bool doRead(byte[] buffer , int len)
	{
		_packageManage.add(cast(ubyte[])buffer[0 .. len]);
		return true;
	}

	 bool doWrite(byte[] buf)
	{
		auto ok = super.doWrite(buf, null, null) >= 0;
		
		if (ok == false)
		{
			_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_WRITE_FAILED, "write data to client is failed");
		}
		
		return ok;
	}

	override  bool onEstablished()
	{
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_CONNECTD, "client inconming....");
		return super.onEstablished();
	}

	override  bool onClose()
	{
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from client!");
		return super.onClose();
	}


	override int getFd()
	{
		return super.getFd();
	}
	
	string getIp()
	{
		return _socket.remoteAddress.toAddrString;
	}
	
	string getPort()
	{
		return _socket.remoteAddress.toPortString;
	}
	
	void disconnect()
	{
		this.close();	
	}

private:
	RpcEventInterface _socketEventDelegate;
	RpcRecvPackageManage _packageManage;
}


//
//class RpcServerSslSocket:AsyncTcpBase, RpcSocketBaseInterface{
//	
//public:
//	this(Poll poll, RpcEventInterface rpcEventDalegate)
//	{
//		readBuff = new byte[RPC_PACKAGE_MAX];
//		
//		_socketEventDelegate = rpcEventDalegate;
//		_packageManage = new RpcRecvPackageManage(this, rpcEventDalegate);
//		
//		super(poll);
//	}
//	
//	~this()
//	{
//		
//	}
//	
//	override  bool doRead(byte[] buffer , int len)
//	{
//		_packageManage.add(cast(ubyte[])buffer[0 .. len]);
//		return true;
//	}
//	
//	bool doWrite(byte[] buf)
//	{
//		auto ok = super.doWrite(buf, null, null) >= 0;
//		
//		if (ok == false)
//		{
//			_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_WRITE_FAILED, "write data to client is failed");
//		}
//		
//		return ok;
//	}
//	
//	override  bool onEstablished()
//	{
//		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_CONNECTD, "client inconming....");
//		return super.onEstablished();
//	}
//	
//	override  bool onClose()
//	{
//		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from client!");
//		return super.onClose();
//	}
//	
//	
//	override int getFd()
//	{
//		return super.getFd();
//	}
//	
//	string getIp()
//	{
//		return _socket.remoteAddress.toAddrString;
//	}
//	
//	string getPort()
//	{
//		return _socket.remoteAddress.toPortString;
//	}
//	
//	void disconnect()
//	{
//		this.close();	
//	}
//	
//private:
//	RpcEventInterface _socketEventDelegate;
//	RpcRecvPackageManage _packageManage;
//}


