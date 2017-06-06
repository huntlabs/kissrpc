module KissRpc.rpc_response;
import KissRpc.rpc_request;

enum RESPONSE_STATUS
{
	RS_OK,
	RS_TIMEOUT,
	RS_FAILD,
}

alias rpc_request rpc_response;