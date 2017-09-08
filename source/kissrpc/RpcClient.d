module kissrpc.RpcClient;

import kissrpc.RpcRequest;
import kissrpc.Unit;
import kissrpc.RpcResponse;
import kissrpc.RpcBinaryPackage;
import kissrpc.RpcClientSocket;
import kissrpc.RpcEventInterface;
import kissrpc.RpcPackageBase;
import kissrpc.RpcSocketBaseInterface;
import kissrpc.RpcEventInterface;
import kissrpc.RpcSendPackageManage;
import kissrpc.Logs;

import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.ByteBuffer;

import std.parallelism;
import std.stdio;
import std.experimental.logger.core;


alias  ReponsCallback =  void delegate(RpcResponse);


class RpcClient:RpcEventInterface{

	this(ClientSocketEventInterface socketEvent)
	{
		clientSocketEvent = socketEvent;
		sendPackManage = new RpcSendPackageManage(this);
		defaultPoolThreads = RPC_CLIENT_DEFAULT_THREAD_POOL;
		compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO;
	}
	
	void bind(string className, string funcName)
	{
		string key = className ~ "." ~ funcName;
		deWritefln("rpc client bind:%s", key);
	}

	void bindCallback(size_t funcId, ReponsCallback callback)
	{
		rpcCallbackMap[funcId] = callback;
	}

	
	bool requestRemoteCall(RpcRequest req, RPC_PACKAGE_PROTOCOL protocol)
	{	
		packMessageCount++;
		req.setSequence(packMessageCount);
		req.setSocket(clientSocket);

		if(req.getCompressType == RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO)
		{
			req.setCompressType(this.compressType);
		}

		deWritefln("rpc client request remote call:%s, id:%s", req.getCallFuncName(), req.getCallFuncId);
		return sendPackManage.add(req);
	}

	void rpcRecvPackageEvent(RpcSocketBaseInterface socket, RpcBinaryPackage pack)
	{

		if(sendPackManage.remove(pack.getSequenceId))
		{
			deWritefln("client recv package event, hander len:%s, package size:%s, ver:%s, func id:%s, sequence id:%s, body size:%s, compress:%s", 
				pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getFuncId, pack.getSequenceId, pack.getBodySize, pack.getCompressType);

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

			auto rpcResp = new RpcRequest(socket);

			rpcResp.setSequence(pack.getSequenceId());
			rpcResp.setNonblock(pack.getNonblock());
			rpcResp.setCompressType(pack.getCompressType);
			rpcResp.bindFunc(pack.getFuncId());
			rpcResp.push(pack.getPayload());

			if(pack.getStatusCode != RPC_PACKAGE_STATUS_CODE.RPSC_OK)
			{
				logWarning("server recv binary package is failed, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s, status code:%s", 
					pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getSequenceId, pack.getBodySize, pack.getStatusCode);
				
				rpcResp.setStatus(RESPONSE_STATUS.RS_FAILD);
				
			}else
			{
				rpcResp.setStatus(RESPONSE_STATUS.RS_OK);	
				deWritefln("rpc server response call, func:%s, arg num:%s", rpcResp.getCallFuncName(), rpcResp.getArgsNum());			
			}
			
			if(pack.getNonblock)
			{
				deWritefln("async call from rpc server response, func:%s, arg num:%s", rpcResp.getCallFuncName(), rpcResp.getArgsNum());			
			}else
			{
				deWritefln("sync call from rpc server response, func:%s, arg num:%s", rpcResp.getCallFuncName(), rpcResp.getArgsNum());			
			}

			auto callback = rpcCallbackMap.get(rpcResp.getCallFuncId, null);
			
			if(callback !is null)
			{
				callback(rpcResp);
			}else
			{
				logError("server rpc call function is not bind, function name:%s", rpcResp.getCallFuncName);
			}

		}else
		{
			logWarning("Accept error, client recv response failed, package is timeout!!!, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s", 
				pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getSequenceId, pack.getBodySize);
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

			auto callback = rpcCallbackMap.get(rpcResp.getCallFuncId, null);

			if(callback !is null)
			{
				callback(rpcResp);
			}else
			{
				logError("server rpc call function is not bind, function name:%s", rpcResp.getCallFuncName);
			}
	}


	void socketEvent(RpcSocketBaseInterface socket, const SOCKET_STATUS status,const string statusStr)
	{
		// logInfo("client socket status info:%s", statusStr);
		switch(status)
		{
			case SOCKET_STATUS.SE_CONNECTD:
				 auto t = task(&clientSocketEvent.connectd, socket); 
				 taskPool.put(t);
				 break;

			case SOCKET_STATUS.SE_DISCONNECTD: 
				auto t = task(&clientSocketEvent.disconnectd, socket); 
				taskPool.put(t);
				break;
			
			case SOCKET_STATUS.SE_READ_FAILED : 
				 auto t = task(&clientSocketEvent.readFailed, socket); 
				 taskPool.put(t);
				 break;

			case SOCKET_STATUS.SE_WRITE_FAILED: 
				auto t = task(&clientSocketEvent.writeFailed, socket); 
				taskPool.put(t);
				break;
		
			default:
				logError("client socket status is fatal!!", statusStr);
				return;
		}

	}

	void connect(string ip, ushort port, AsynchronousChannelSelector sel)
	{
		clientSocket = new RpcClientSocket(ip, port, sel, this);
	}

	void reConnect()
	{
		clientSocket.reConnect();
	}

	ulong getWaitResponseNum()
	{
		return sendPackManage.getWaitResponseNum;
	}

	void setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE type)
	{
		compressType = type;
	}
	
private:
	RpcSendPackageManage sendPackManage;
	RPC_PACKAGE_COMPRESS_TYPE compressType;

	ReponsCallback[size_t] rpcCallbackMap;

	ulong packMessageCount;

	RpcClientSocket clientSocket;
	ClientSocketEventInterface clientSocketEvent;
}
