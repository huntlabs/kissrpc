module kissrpc.RpcRecvPackageManage;

import kissrpc.RpcBinaryPackage;
import kissrpc.RpcServerSocket;
import kissrpc.RpcEventInterface;
import kissrpc.RpcSocketBaseInterface;
import kissrpc.Unit;
import kissrpc.Logs;

import kissrpc.RpcClientSocket;

import std.parallelism;
import std.stdio;
import core.thread;
import std.format;

import std.experimental.logger;

class CapnprotoRecvPackage
{
	this()
	{
		binaryPackage = new RpcBinaryPackage(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF);
		hander = new ubyte[binaryPackage.getHanderSize];
		recvRemainBytes = hander.length;
	}


	ubyte[] parse(ubyte[] bytes, ref bool isOk)
	{
		// log("parse ",bytes,", hander.length ",hander.length);
		ulong cpySize = bytes.length > recvRemainBytes? recvRemainBytes : bytes.length;
		ulong bytesPos = 0;
		// log("parseState ",parseState, ", recvRemainBytes ",recvRemainBytes, ", bytes.length ", bytes.length,", isOk ",isOk);
		if(parseState == 0)
		{
			hander[handerPos .. handerPos + cpySize] = bytes[bytesPos .. bytesPos + cpySize];
			// log(format("handerPos = %s, hander = %s",handerPos,hander));

			handerPos += cpySize;
			bytesPos  += cpySize;

			recvRemainBytes -= cpySize;

			if(recvRemainBytes == 0)
			{		
				if(binaryPackage.fromStreamForHander(hander))
				{
					payload = new ubyte[binaryPackage.getBodySize()];
					recvRemainBytes = payload.length;
					parseState = 1;
					return this.parse(bytes[bytesPos .. bytesPos + (bytes.length - cpySize)], isOk);
				}
				else  
					return null;
			}
		}

		if(parseState == 1 && recvRemainBytes >= 0)
		{	
			// log(format("payloadPos = %s, payload = %s",payloadPos,payload));	
			payload[payloadPos .. payloadPos + cpySize] = bytes[bytesPos .. bytesPos + cpySize];

			payloadPos += cpySize;
			bytesPos  += cpySize;
			recvRemainBytes -= cpySize;

			if(recvRemainBytes == 0) 
			{
				isOk = binaryPackage.fromStreamForPayload(payload);
				if (!isOk) {
					log("body check error!!!");
					return null;
				}
			}
		}
		

		return bytes[bytesPos .. bytesPos + (bytes.length-cpySize)];
	}

	RpcBinaryPackage getPackage()
	{
		return binaryPackage;
	}

	bool checkHanderValid()
	{
		return binaryPackage.checkHanderValid;
	}

	bool checkPackageValid()
	{
		return binaryPackage.checkHanderValid && payloadPos == payload.length;
	}

private:
	ubyte[] hander;
	ubyte[] payload;
	int parseState;

	ulong handerPos, payloadPos;

	ulong recvRemainBytes;

	RpcBinaryPackage binaryPackage;
}

class RpcRecvPackageManage
{
	this(RpcSocketBaseInterface baseSocket, RpcEventInterface rpcDelegate)
	{
		rpcEventDelegate = rpcDelegate;
		socket = baseSocket;
	}


	void add(ubyte[] bytes)
	{
		// log("add ",bytes);
		do{
			auto pack = recvPackage.get(id, new CapnprotoRecvPackage);
		
			bool parseOk = false;

			recvPackage[id] = pack;
			
			
			bytes = pack.parse(bytes, parseOk);
			if (bytes is null) {
				logError(format("parse head error !!!!"));
				socket.disconnect();
				break;
			}

			// log("bytes.length ",bytes.length,", parseOk ",parseOk,", id ", id);
			if(parseOk)
			{
				auto capnprotoPack = pack.getPackage();
				
				// log("pack.checkHanderValid() ",pack.checkHanderValid());
				if(pack.checkHanderValid())
				{
					// log("pack.checkPackageValid() ",pack.checkPackageValid());
					if(pack.checkPackageValid)
					{	
						if (capnprotoPack.getFuncId() == 0) {
							logInfo("recv heart kick");
							if (cast(RpcClientSocket)socket !is null) {

							}
							else if(cast(RpcServerSocket)socket !is null) {
								socket.write(cast(byte[])capnprotoPack.getHead());
							}
						}else {
							rpcEventDelegate.rpcRecvPackageEvent(socket, capnprotoPack);
						}
						recvPackage.remove(id);
						id++;
					}else{
						logError("parse package check hander is error, package data:%s", bytes);
						socket.disconnect();
						break;
					}
				}else
				{
					logError(format("parse parseOk head error !!!!"));
					socket.disconnect();
					break;	
				}
			}
		}while(bytes.length > 0);
	}

private:
	ulong id;
	CapnprotoRecvPackage[ulong] recvPackage;
	RpcEventInterface rpcEventDelegate;
	RpcSocketBaseInterface socket;
}
