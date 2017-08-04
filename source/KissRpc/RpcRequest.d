module KissRpc.RpcRequest;

import KissRpc.Logs;
import KissRpc.Unit;
import KissRpc.Endian;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.RpcResponse;


import std.stdio;
import std.traits;
import core.sync.semaphore;


alias  REQUEST_STATUS = RESPONSE_STATUS; 

class RpcRequest
{
	this(const RPC_PACKAGE_COMPRESS_TYPE type = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS)
	{
		timeOut = secondsTimeOut;
		timestamp = RPC_SYSTEM_TIMESTAMP;
		semaphore = new Semaphore;
		nonblock = true;
		compressType = type;
	}

	this(RpcRequest req)
	{
		this.baseSocket = req.baseSocket;
		this.funcId = req.funcId;
		this.sequeNum = req.sequeNum;
		this.nonblock = req.nonblock;
		this.compressType = req.compressType;
	}

	this(RpcSocketBaseInterface socket)
	{
		baseSocket = socket;
	}


	void push(ubyte[] arg)
	{
		funcArg = arg;
	}



	bool pop(ref ubyte[] arg)
	{
		arg = funcArg;

		return true;
	}

	void bindFunc(const size_t id)
	{
		funcId = id;
	}

	ulong getArgsNum()const
	{
		return 1;
	}

	string getCallFuncName()const
	{
		return RpcBindFunctionMap[funcId];
	}

	size_t getCallFuncId()const
	{
		return funcId;
	}

	ubyte[] getFunArgList()
	{
		return funcArg;
	}

	void setSocket(RpcSocketBaseInterface socket)
	{
		baseSocket = socket;
	}

	auto getSocket()
	{
		return baseSocket;
	}

	auto getTimestamp()const
	{
		return timestamp;
	}

	void setSequence(ulong seque)
	{
		sequeNum = seque;
	}

	auto getSequence()const
	{
		return sequeNum;
	}

	auto getTimeout()const
	{
		return timeOut;
	}

	void setStatus(RESPONSE_STATUS status)
	{
		response_status = status;
	}

	auto getStatus()const
	{
		return response_status;
	}

	auto getNonblock()const
	{
		return nonblock;
	}

	void setNonblock(bool isNonblock)
	{
		nonblock = isNonblock;
	}

	void semaphoreWait()
	{
		nonblock = false;
		semaphore.wait();
	}

	void semaphoreRelease()
	{
		semaphore.notify();
	}

	RPC_PACKAGE_COMPRESS_TYPE getCompressType()
	{
		return compressType;
	}

	void setCompressType(RPC_PACKAGE_COMPRESS_TYPE type)
	{
		compressType = type;
	}

private:

	RPC_PACKAGE_COMPRESS_TYPE compressType;

	RESPONSE_STATUS response_status;

	ubyte[] funcArg;
	size_t funcId;
	RpcSocketBaseInterface baseSocket;
	Semaphore semaphore;

	bool nonblock;

	ulong timestamp;
	ulong timeOut;
	ulong sequeNum;
}
