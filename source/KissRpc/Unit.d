module KissRpc.Unit;

import std.traits;

shared string[size_t] RpcBindFunctionMap;
const ulong RPC_PACKAGE_MAX = 64*1024;
const uint RPC_REQUEST_TIMEOUT_SECONDS = 20;
const uint RPC_CLIENT_DEFAULT_THREAD_POOL = 1;

shared ulong RPC_PACKAGE_COMPRESS_DYNAMIC_VALUE = 200;
shared ulong RPC_SYSTEM_TIMESTAMP = 0;
shared string RPC_SYSTEM_TIMESTAMP_STR;


// rpc package hander flags
const ubyte[2] RPC_HANDER_MAGIC = [0xff, 0xff];
const ubyte RPC_HANDER_VERSION = 0x01;

const short RPC_HANDER_COMPRESS_FLAG = cast(short)0xf000;
const short RPC_HANDER_CPNPRESS_TYPE_FLAG = cast(short)0x0f00;
const short RPC_HANDER_SERI_FLAG = cast(short)0x000f;

const ubyte RPC_HANDER_HB_FLAG = cast(ubyte)(1 << 8);
const ubyte RPC_HANDER_OW_FLAG = cast(ubyte)(1 << 7);
const ubyte RPC_HANDER_RP_FLAG = cast(ubyte)(1 << 6);
const ubyte RPC_HANDER_NONBLOCK_FLAG = cast(ubyte)(1 << 5);
const ubyte RPC_HANDER_STATUS_CODE_FLAG = cast(ubyte) 0x0f;

enum RPC_PACKAGE_COMPRESS_TYPE
{
	RPCT_NO,
	RPCT_DYNAMIC,
	RPCT_COMPRESS,
}

enum RPC_PACKAGE_PROTOCOL
{
	TPP_JSON,
	TPP_XML,
	TPP_PROTO_BUF,
	TPP_FLAT_BUF,
	TPP_CAPNP_BUF,
}
