module kissrpc.RpcResponse;

import kissrpc.RpcRequest;

enum RESPONSE_STATUS
{
	RS_OK,
	RS_TIMEOUT,
	RS_FAILD,
}

alias RpcRequest RpcResponse;
