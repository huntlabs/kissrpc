module KissRpc.RpcPackageBase;

import KissRpc.RpcRequest;
import KissRpc.RpcResponse;

interface RpcPackageBase{
	RpcRequest getRequestData();
	RpcResponse getResponseData();

	ubyte[] toBinaryStream();
}
