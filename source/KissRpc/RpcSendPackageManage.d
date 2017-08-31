module KissRpc.RpcSendPackageManage;

import KissRpc.RpcBinaryPackage;
import KissRpc.RpcPackageBase;
import KissRpc.RpcResponse;
import KissRpc.RpcRequest;
import KissRpc.RpcEventInterface;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.Unit;
import KissRpc.Logs;

import std.datetime;
import core.thread;
import core.memory:GC;

import std.stdio;

 class RpcSendPackageManage:Thread
{
	this(RpcEventInterface rpc_event)
	{
		RPC_SYSTEM_TIMESTAMP = Clock.currStdTime().stdTimeToUnixTime!(long)();

		clientEventInterface = rpc_event;

		super(&this.threadRun);
		super.start();

	}


	bool add(RpcRequest req, bool checkble = true)
	{
		synchronized(this)
		{
			auto streamBinaryPackge = new RpcBinaryPackage(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, req.getSequence, req.getCompressType, req.getNonblock, req.getCallFuncId);

			auto sendStream = streamBinaryPackge.toStream(req.getFunArgList());

			bool isOk = req.getSocket.write(cast(byte[]) sendStream);

			if(isOk)
			{
				if(checkble)
				{
					sendPack[req.getSequence()] = req;
				}

				deWritefln("send binary stream, sequece:%s, funcId:%s, funcName:%s, length:%s",req.getSequence, req.getCallFuncId, req.getCallFuncName, sendStream.length);
				
			}else
			{
				req.setStatus(RESPONSE_STATUS.RS_FAILD);
				clientEventInterface.rpcSendPackageEvent(req);
			}

			return isOk;
		}
	}

	bool remove(const ulong index)
	{
		synchronized(this)
		{
			return sendPack.remove(index);
		}
	}


	ulong getWaitResponseNum()
	{
		return sendPack.length;
	}

protected:

	void threadRun()
	{
			while(this.isRunning())
			{
				synchronized(this)
				{
						RPC_SYSTEM_TIMESTAMP = Clock.currStdTime().stdTimeToUnixTime!(long)();
						RPC_SYSTEM_TIMESTAMP_STR = SysTime.fromUnixTime(RPC_SYSTEM_TIMESTAMP).toISOExtString();
						
						foreach(k, ref req; sendPack)
						{							
							if(req.getTimestamp() + req.getTimeout() < RPC_SYSTEM_TIMESTAMP)
							{
								req.setStatus(RESPONSE_STATUS.RS_TIMEOUT);
								clientEventInterface.rpcSendPackageEvent(req);
								this.remove(k);
							}
						}
				}
				this.sleep(dur!("msecs")(100));
			}
	}

private:
	RpcRequest[ulong] sendPack;
	RpcEventInterface clientEventInterface;
}
