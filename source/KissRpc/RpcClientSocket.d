module KissRpc.RpcClientSocket;

import KissRpc.RpcRecvPackageManage;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Unit;


import kiss.aio.AsyncTcpBase;
import kiss.event.Poll;
import kiss.time.Timer;
import kiss.aio.AsyncTcpClient;

import std.stdio;
import std.socket;
import std.conv;

import core.thread;


class RpcClientSocket: AsyncTcpClient, RpcSocketBaseInterface
{
	this(string ip, ushort port, Group poll, RpcEventInterface rpcEventDelegate)
	{	
		readBuff = new byte[RPC_PACKAGE_MAX];
		super(poll);
		super.open(ip, port);

		_packageManage = new RpcRecvPackageManage(this, rpcEventDelegate);
		_socketEventDelegate = rpcEventDelegate;
	}


	override bool onEstablished()
	{
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_CONNECTD, "connect to server is ok!");
		return super.onEstablished();
	}
	
	override bool doRead(byte[] buffer , int len)
	{
		_packageManage.add(cast(ubyte[])buffer[0..len]);
		return true;
	}

	bool doWrite(byte[] buf)
	{
		auto ok = super.doWrite(buf, null, null) >= 0;

		if (ok == false)
		{
			_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_WRITE_FAILED, "write data to server is failed");
		}

		return ok;
	}


	override bool onClose()
	{
		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from server!");
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
	TimerFd _echo_time;
}




