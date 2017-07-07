﻿module KissRpc.RpcClient;

import KissRpc.RpcRequest;
import KissRpc.Unit;
import KissRpc.RpcResponse;
import KissRpc.RpcBinaryPackage;
import KissRpc.RpcCapnprotoPackage;
import KissRpc.RpcClientSocket;
import KissRpc.RpcEventInterface;
import KissRpc.RpcPackageBase;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSendPackageManage;
import KissRpc.Logs;

import kiss.event.GroupPoll;
import kiss.aio.AsyncTcpServer;

import std.parallelism;
import std.stdio;


alias  ReponsCallback =  void delegate(RpcResponse);


class RpcClient:RpcEventInterface{

	this(ClientSocketEventInterface socketEvent)
	{
		clientSocketEvent = socketEvent;
		sendPackManage = new RpcSendPackageManage(this);
		defaultPoolThreads = RPC_CLIENT_DEFAULT_THREAD_POOL;
	}
	
	void bind(string className, string funcName)
	{
		string key = className ~ "." ~ funcName;
		deWritefln("rpc client bind:%s", key);
	}

	void bindCallback(string funcName, ReponsCallback callback)
	{
		rpcCallbackMap[funcName] = callback;
	}

	
	bool requestRemoteCall(RpcRequest req)
	{	
		packMessageCount++;
		req.setSequence(packMessageCount);
		req.setSocket(clientSocket);

		deWritefln("rpc client request remote call:%s", req.getCallFuncName());
		return sendPackManage.add(req);
	}

	void rpcRecvPackageEvent(RpcSocketBaseInterface socket, RpcBinaryPackage pack)
	{

		if(sendPackManage.remove(pack.getSequenceId))
		{
			deWritefln("client recv package event, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s", 
				pack.getHanderSize, pack.getPackgeSize, pack.getVersion, pack.getSequenceId, pack.getBodySize);

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

			auto rpcResp = packageBase.getResponseData();

			rpcResp.setSequence(pack.getSequenceId());
			rpcResp.setNonblock(pack.getNonblock());

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
				deWritefln("async call form rpc server response, func:%s, arg num:%s", rpcResp.getCallFuncName(), rpcResp.getArgsNum());			
			}else
			{
				deWritefln("sync call form rpc server response, func:%s, arg num:%s", rpcResp.getCallFuncName(), rpcResp.getArgsNum());			
			}

			auto callback = rpcCallbackMap.get(rpcResp.getCallFuncName, null);
			
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

			auto callback = rpcCallbackMap.get(rpcResp.getCallFuncName, null);

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
		logInfo("client socket status info:%s", statusStr);
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

	void connect(string ip, ushort port, GroupPoll!() poll)
	{
		clientSocket = new RpcClientSocket(ip, port, poll, this);
	}

	ulong getWaitResponseNum()
	{
		return sendPackManage.getWaitResponseNum;
	}

	
private:
	RpcSendPackageManage sendPackManage;

	ReponsCallback[string] rpcCallbackMap;

	ulong packMessageCount;

	RpcClientSocket clientSocket;
	ClientSocketEventInterface clientSocketEvent;
}
