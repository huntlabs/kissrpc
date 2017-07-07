module KissRpc.RpcEventInterface;

import KissRpc.RpcBinaryPackage;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.RpcResponse;

enum SOCKET_STATUS{
	SE_CONNECTD,
	SE_DISCONNECTD,
	SE_WRITE_FAILED,
	SE_READ_FAILED,
	SE_LISTEN_FAILED,
}

interface RpcEventInterface
{
	void rpcRecvPackageEvent(RpcSocketBaseInterface socket, RpcBinaryPackage recvPackage);
	void rpcSendPackageEvent(RpcResponse resp);

	void socketEvent(RpcSocketBaseInterface socket,const SOCKET_STATUS status, const string statusStr);
}
