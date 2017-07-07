module KissRpc.RpcRecvPackageManage;

import KissRpc.RpcCapnprotoPayload;
import KissRpc.RpcBinaryPackage;
import KissRpc.RpcServerSocket;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Unit;

import std.parallelism;
import std.stdio;
import core.thread;

class CapnprotoRecvPackage
{
	this()
	{
		binaryPackage = new RpcBinaryPackage(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, 0);
		hander = new ubyte[binaryPackage.getHanderSize];
		recvRemainBytes = hander.length;
	}


	ubyte[] parse(ubyte[] bytes, ref bool isOk)
	{
		ulong cpySize = bytes.length > recvRemainBytes? recvRemainBytes : bytes.length;
		ulong bytesPos = 0;

		if(parseState == 0)
		{
			hander[handerPos .. handerPos + cpySize] = bytes[bytesPos .. bytesPos + cpySize];

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
			}
		}

		if(parseState == 1 && recvRemainBytes > 0)
		{		
			payload[payloadPos .. payloadPos + cpySize] = bytes[bytesPos .. bytesPos + cpySize];

			payloadPos += cpySize;
			bytesPos  += cpySize;
			recvRemainBytes -= cpySize;

			if(recvRemainBytes == 0) 
			{
				isOk = binaryPackage.fromStreamForPayload(payload);
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
		 do{
				auto pack = recvPackage.get(id, new CapnprotoRecvPackage);
	
				bool parseOk = false;

				recvPackage[id] = pack;
				
				bytes = pack.parse(bytes, parseOk);
			
				if(parseOk)
				{
						auto capnprotoPack = pack.getPackage();
						
						if(pack.checkHanderValid())
						{
							if(pack.checkPackageValid)
							{
								rpcEventDelegate.rpcRecvPackageEvent(socket, capnprotoPack);
								recvPackage.remove(id);
								id++;
							}

						}else
						{
							capnprotoPack.setStatusCode(RPC_PACKAGE_STATUS_CODE.RPSC_FAILED);
							recvPackage.remove(id);
							rpcEventDelegate.rpcRecvPackageEvent(socket, capnprotoPack);		
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
