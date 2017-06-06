module KissRpc.rpc_server_socket;

import kiss.aio.AsyncTcpBase;
import kiss.event.Poll;

import KissRpc.rpc_recv_package_manage;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_socket_base_interface;
import KissRpc.unit;

import std.socket;
import std.stdio;
import core.thread;
import std.conv;

class rpc_server_socket:AsyncTcpBase, rpc_socket_base_interface{
public:
	
	this(Poll poll, rpc_event_interface rpcEventDalegate)
	{
		readBuff = new byte[RPC_PACKAGE_MAX];

		_socketEventDelegate = rpcEventDalegate;
		_packageManage = new rpc_recv_package_manage(this, rpcEventDalegate);

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
		return super.doWrite(buf, null, null) >= 0;
	}

	override  bool onEstablished()
	{
		_socketEventDelegate.socket_event(this, SOCKET_STATUS.SE_CONNECTD, "client inconming....");
		return super.onEstablished();
	}

	override  bool onClose()
	{
		_socketEventDelegate.socket_event(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from client!");
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
}





