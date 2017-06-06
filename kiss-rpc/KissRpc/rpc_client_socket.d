module KissRpc.rpc_client_socket;

import kiss.aio.AsyncTcpBase;
import kiss.event.Poll;
import kiss.time.Timer;
import kiss.aio.AsyncTcpClient;

import std.stdio;
import core.thread;
import std.socket;
import std.conv;

import KissRpc.rpc_recv_package_manage;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_socket_base_interface;
import KissRpc.unit;

class rpc_client_socket: AsyncTcpClient, rpc_socket_base_interface
{
	this(string ip, ushort port, Group poll, rpc_event_interface rpcEventDelegate)
	{	
		readBuff = new byte[RPC_PACKAGE_MAX];
		super(poll);
		super.open(ip, port);

		_packageManage = new rpc_recv_package_manage(this, rpcEventDelegate);
		_socketEventDelegate = rpcEventDelegate;
	}


	override bool onEstablished()
	{
		_socketEventDelegate.socket_event(this, SOCKET_STATUS.SE_CONNECTD, "connect to server is ok!");
		return super.onEstablished();
	}
	
	override bool doRead(byte[] buffer , int len)
	{
		_packageManage.add(cast(ubyte[])buffer[0..len]);
		return true;
	}

	bool doWrite(byte[] buf)
	{

		return super.doWrite(buf, null, null) >= 0;
	}


	override bool onClose()
	{
		_socketEventDelegate.socket_event(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from server!");
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
	rpc_event_interface _socketEventDelegate;
	rpc_recv_package_manage _packageManage;
	TimerFd _echo_time;
}




