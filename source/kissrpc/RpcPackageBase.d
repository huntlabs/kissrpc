module kissrpc.RpcPackageBase;

import kissrpc.RpcRequest;
import kissrpc.RpcResponse;

interface RpcPackageBase{
	RpcRequest getRequestData();
	RpcResponse getResponseData();

	ubyte[] toBinaryStream();
}
