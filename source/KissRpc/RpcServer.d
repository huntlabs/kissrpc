module KissRpc.RpcServer;

import KissRpc.RpcRequest;
import KissRpc.Unit;
import KissRpc.RpcResponse;
import KissRpc.RpcBinaryPackage;
import KissRpc.RpcCapnprotoPackage;
import KissRpc.RpcServerSocket;
import KissRpc.RpcEventInterface;
import KissRpc.RpcPackageBase;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.RpcSendPackageManage;
import KissRpc.Logs;

import kiss.event.GroupPoll;
import kiss.aio.AsyncGroupTcpServer;
import std.stdio;

alias RequestCallback = void delegate(RpcRequest);

class RpcServer:RpcEventInterface{

	this(ServerSocketEventInterface socketEvent)
	{
		serverSocketEvent = socketEvent;
		sendPackManage = new RpcSendPackageManage(this);
	}

	void bind(string className, string funcName)
	{
		string key = className ~ "." ~ funcName;
		rpcCallbackMap[key] = (RpcRequest){};
		
		deWritefln("rpc server bind:%s", key);
	}
	
	void bindCallback(string funcName, RequestCallback callback)
	{
		rpcCallbackMap[funcName] = callback;
		deWritefln("rpc server bind callback:%s, addr:%s",funcName, callback);
	}

	bool RpcResponseRemoteCall(RpcResponse resp)
	{
		deWritefln("rpc response remote call, func:%s", resp.getCallFuncName);
		return 	sendPackManage.add(resp, false);
	}


	void rpcRecvPackageEvent(RpcSocketBaseInterface socket, RpcBinaryPackage pack)
	{
		deWritefln("server recv package event, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s", 
					pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getSequenceId, pack.getBodySize);

		if(pack.getStatusCode != RPC_PACKAGE_STATUS_CODE.RPSC_OK)
		{
			logWarning("server recv binary package is failed, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s, status code:%s", 
				pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getSequenceId, pack.getBodySize, pack.getStatusCode);
		
		}else
		{
			RpcPackageBase packageBase;
			
			switch(pack.getSerializedType)
			{
				case RPC_PACKAGE_PROTOCOL.TPP_JSON:break;
				case RPC_PACKAGE_PROTOCOL.TPP_XML: break;
				case RPC_PACKAGE_PROTOCOL.TPP_PROTO_BUF: break;
				case RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF:  break;
				case RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF: packageBase = new RpcCapnprotoPackage(socket, pack.getPayload()); break;
					
				default:
					logWarning("unpack serialized type is failed!, type:%d", pack.getSerializedType());
			}
			
			auto rpcReq = packageBase.getRequestData();
			rpcReq.setSequence(pack.getSequenceId());
			rpcReq.setNonblock(pack.getNonblock());

			deWritefln("rpc client request call, func:%s, arg num:%s", rpcReq.getCallFuncName(), rpcReq.getArgsNum());

			auto callback = rpcCallbackMap.get(rpcReq.getCallFuncName, null);

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

	bool listen(string ip, ushort port, GroupPoll!() poll)
	{
		auto server_poll = new AsyncGroupTcpServer!(RpcServerSocket, RpcEventInterface)(poll, this);
		return server_poll.open(ip , port);
	}

private:
	RpcSendPackageManage sendPackManage;

	ServerSocketEventInterface serverSocketEvent;
	RequestCallback[string] rpcCallbackMap;
}
