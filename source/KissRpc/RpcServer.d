module KissRpc.RpcServer;

import KissRpc.RpcRequest;
import KissRpc.Unit;
import KissRpc.RpcResponse;
import KissRpc.RpcBinaryPackage;
import KissRpc.RpcServerSocket;
import KissRpc.RpcEventInterface;
import KissRpc.RpcPackageBase;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.RpcSendPackageManage;
import KissRpc.Logs;

// import kiss.event.GroupPoll;
// import kiss.aio.AsyncGroupTcpServer;

import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.AsynchronousSocketChannel;
import kiss.net.TcpAcceptor;


import std.stdio;

alias RequestCallback = void delegate(RpcRequest);

class RpcServer:TcpAcceptor, RpcEventInterface{

	this(string ip, ushort port, AsynchronousChannelThreadGroup group, ServerSocketEventInterface socketEvent)
	{
		serverSocketEvent = socketEvent;
		sendPackManage = new RpcSendPackageManage(this);
		compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO;

		super(ip, port, group.getWorkSelector());
	}

	override void onAcceptCompleted(void* attachment, AsynchronousSocketChannel result) {
		RpcServerSocket server = new RpcServerSocket(result, this);
	}
    override void onAcceptFailed(void* attachment) {
		deWritefln("rpc acceptFailed");
	}

	void bind(string className, string funcName)
	{
		string key = className ~ "." ~ funcName;
		deWritefln("rpc server bind:%s", key);
	}
	
	void bindCallback(const size_t funcId, RequestCallback callback)
	{
		rpcCallbackMap[funcId] = callback;
		deWritefln("rpc server bind callback:%s, %s, addr:%s",funcId, RpcBindFunctionMap[funcId], callback);
	}

	bool RpcResponseRemoteCall(RpcResponse resp, RPC_PACKAGE_PROTOCOL protocol)
	{
		if(resp.getCompressType == RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO)
		{
			resp.setCompressType(this.compressType);
		}

		deWritefln("rpc response remote call:%s, id:%s", resp.getCallFuncName, resp.getCallFuncId);
		return 	sendPackManage.add(resp, false);
	}


	void rpcRecvPackageEvent(RpcSocketBaseInterface socket, RpcBinaryPackage pack)
	{
		deWritefln("server recv package event, hander len:%s, package size:%s, ver:%s, func id:%s, sequence id:%s, body size:%s, compress:%s", 
					pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getFuncId, pack.getSequenceId, pack.getBodySize, pack.getCompressType);

		if(pack.getStatusCode != RPC_PACKAGE_STATUS_CODE.RPSC_OK)
		{
			logWarning("server recv binary package is failed, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s, compress:%s, status code:%s", 
				pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getSequenceId, pack.getBodySize, pack.getCompressType, pack.getStatusCode);
		
		}else
		{
			RpcPackageBase packageBase;

			switch(pack.getSerializedType)
			{
				case RPC_PACKAGE_PROTOCOL.TPP_JSON:break;
				case RPC_PACKAGE_PROTOCOL.TPP_XML: break;
				case RPC_PACKAGE_PROTOCOL.TPP_PROTO_BUF: break;
				case RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF:  break;
				case RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF: break;
					
				default:
					logWarning("unpack serialized type is failed!, type:%d", pack.getSerializedType());
			}

			auto rpcReq = new RpcRequest(socket);

			rpcReq.setSequence(pack.getSequenceId());
			rpcReq.setNonblock(pack.getNonblock());
			rpcReq.setCompressType(pack.getCompressType());
			rpcReq.bindFunc(pack.getFuncId());
			rpcReq.push(pack.getPayload());

			deWritefln("rpc client request call, func:%s, arg num:%s", rpcReq.getCallFuncName(), rpcReq.getArgsNum());

			auto callback = rpcCallbackMap.get(rpcReq.getCallFuncId, null);

			if(callback !is null)
			{
					callback(rpcReq);
			}else
			{
					logError("client rpc call function is not bind, function name:%s", rpcReq.getCallFuncName);
			}

		}
	}

	void rpcSendPackageEvent(RpcResponse rpcResp)
	{
		switch(rpcResp.getStatus)
		{
			case RESPONSE_STATUS.RS_TIMEOUT:
				logWarning("response timeout, func:%s, start time:%s, time:%s, sequence:%s", rpcResp.getCallFuncName, rpcResp.getTimestamp, rpcResp.getTimeout, rpcResp.getSequence);
				break;
				
			case RESPONSE_STATUS.RS_FAILD:
				logWarning("request failed, func:%s, start time:%s, time:%s, sequence:%s", rpcResp.getCallFuncName, rpcResp.getTimestamp, rpcResp.getTimeout, rpcResp.getSequence);
				break;
				
			default:
				logWarning("rpc send package event is fatal!!, event type error!");
		}
	}

	void socketEvent(RpcSocketBaseInterface socket, const SOCKET_STATUS status,const string statusStr)
	{
		logInfo("server socket status:%s", statusStr);

		switch(status)
		{
			case SOCKET_STATUS.SE_LISTEN_FAILED: serverSocketEvent.listenFailed(statusStr); break;
			case SOCKET_STATUS.SE_CONNECTD: serverSocketEvent.inconming(socket); break;
			case SOCKET_STATUS.SE_DISCONNECTD:serverSocketEvent.disconnectd(socket); break;
			case SOCKET_STATUS.SE_READ_FAILED: serverSocketEvent.readFailed(socket); break;
			case SOCKET_STATUS.SE_WRITE_FAILED: serverSocketEvent.writeFailed(socket); break;

			default:
				logError("server socket status is fatal!!", statusStr);
		}
	}


	void setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE type)
	{
		compressType = type;
	}

private:
	RpcSendPackageManage sendPackManage;
	RPC_PACKAGE_COMPRESS_TYPE compressType;

	ServerSocketEventInterface serverSocketEvent;
	RequestCallback[size_t] rpcCallbackMap;
}
