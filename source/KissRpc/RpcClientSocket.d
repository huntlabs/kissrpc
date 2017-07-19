module KissRpc.RpcClientSocket;

import KissRpc.RpcRecvPackageManage;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Unit;
import KissRpc.Logs;

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
}


//import deimos.openssl.err;
//import deimos.openssl.rand;
//import deimos.openssl.ssl;
//import deimos.openssl.x509v3;
//
//class RpcClientSslSocket: AsyncTcpClient, RpcSocketBaseInterface
//{
//	this(string ip, ushort port, TSSLContext context, Group poll, RpcEventInterface rpcEventDelegate)
//	{	
//		readBuff = new byte[RPC_PACKAGE_MAX];
//		super(poll);
//		super.open(ip, port);
//		
//		_packageManage = new RpcRecvPackageManage(this, rpcEventDelegate);
//		_socketEventDelegate = rpcEventDelegate;
//
//		context_ = context;
//		accessManager_ = context.accessManager;
//
//	}
//	
//	
//	override bool onEstablished()
//	{
//		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_CONNECTD, "connect to server is ok!");
//
//		if(ssl_ is null) return false;
//
//		auto shutdown = SSL_get_shutdown(ssl_);
//		bool shutdownReceived = (shutdown & SSL_RECEIVED_SHUTDOWN) != 0;
//		bool shutdownSent = (shutdown & SSL_SENT_SHUTDOWN) != 0;
//
//		return super.onEstablished() && !(shutdownReceived && shutdownSent);
//	}
//	
//	override bool doRead(byte[] buffer , int len)
//	{
//		this.checkHandshake();
//
//		int bytes;
//
//		foreach (_; 0 .. maxRecvRetries) {
//			bytes = SSL_read(ssl_, buffer, len);
//			if (bytes >= 0) break;
//			
//			auto errnoCopy = errno;
//			if (SSL_get_error(ssl_, bytes) == SSL_ERROR_SYSCALL) {
//				if (ERR_get_error() == 0 && errnoCopy == EINTR) {
//					// FIXME: Windows.
//					continue;
//				}
//			}
//			throw getSSLException("SSL_read");
//		}
//
//
//		_packageManage.add(cast(ubyte[])buffer[0..len]);
//		return bytes > 0;
//	}
//	
//	bool doWrite(byte[] buf)
//	{
//		this.checkHandshake();
//
//
//		auto ok = super.doWrite(buf, null, null) >= 0;
//		
//		if (ok == false)
//		{
//			_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_WRITE_FAILED, "write data to server is failed");
//		}
//		
//		return ok;
//	}
//	
//	
//	override bool onClose()
//	{
//		_socketEventDelegate.socketEvent(this, SOCKET_STATUS.SE_DISCONNECTD, "disconnect from server!");
//		return super.onClose();
//	}
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
//		if (ssl_ !is null) {
//			// Two-step SSL shutdown.
//			auto rc = SSL_shutdown(ssl_);
//			if (rc == 0) {
//				rc = SSL_shutdown(ssl_);
//			}
//			if (rc < 0) {
//				// Do not throw an exception here as leaving the transport "open" will
//				// probably produce only more errors, and the chance we can do
//				// something about the error e.g. by retrying is very low.
//				logError("Error shutting down SSL: %s", getSSLException());
//			}
//			
//			SSL_free(ssl_);
//			ssl_ = null;
//			ERR_remove_state(0);
//		}
//
//		this.close();
//	}
//
//
//protected:
//
//	void checkHandshake() {
//		enforce(super.isOpen(), new TTransportException(
//				TTransportException.Type.NOT_OPEN));
//		
//		if (ssl_ !is null) return;
//		ssl_ = context_.createSSL();
//		
//		SSL_set_fd(ssl_, socketHandle);
//		int rc = SSL_connect(ssl_);
//
//		enforce(rc > 0, getSSLException());
//		authorize(ssl_, accessManager_, getPeerAddress(),host);
//	}
//
//
//private:
//	RpcEventInterface _socketEventDelegate;
//	RpcRecvPackageManage _packageManage;
//
//	SSL* ssl_;
//	TSSLContext context_;
//	TAccessManager accessManager_;
//}

