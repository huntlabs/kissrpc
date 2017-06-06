module KissRpc.unit;
import std.stdio;
import std.datetime;
import kiss.util.Log;

//alias de_writefln = writefln;
//alias de_writeln = writeln;
//alias log_info = writefln;
//alias log_warning = writefln;
//alias log_error = writefln;
void test(A ...)(A args)
{

}

alias de_writefln = log_debug;
alias de_writeln = log_debug;
alias log_info = test;
alias log_warning = test;
alias log_error = test;

const ubyte[8] RPC_HANDER_MAGIC = [0xaa, 0xbb, 0xcc, 0xdd, 0xaa, 0xaa, 0xaa, 0xff];
const short RPC_HANDER_VERSION = 0x0001;
const ulong RPC_PACKAGE_MAX = 8*1024;

const uint RPC_REQUEST_TIMEOUT_SECONDS = 20;
shared ulong RPC_SYSTEM_TIMESTAMP = 0;

const uint RPC_CLIENT_DEFAULT_THREAD_POOL = 1;