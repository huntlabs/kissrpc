

module kissrpc.RpcClient;


import kissrpc.RpcBase;
import kissrpc.RpcCodec;
import kissrpc.RpcConstant;
import kissrpc.RpcStream;
import kissrpc.RpcStreamClient;

import kiss.event.loop;
import kiss.net.TcpStreamClient;

import std.stdio;
import std.traits;
import core.thread;
import core.sync.semaphore;
import std.experimental.logger.core;


class RpcClient : RpcBase{
public:
    this(EventLoop loop, string host, ushort port, RpcEventHandler handler = null, ubyte protocol = RpcProtocol.FlatBuffer, ubyte compress = RpcCompress.None) {
        super(loop, host, port);
        _protocol = protocol;
        _compress = compress;
        _clientSeqId = 0;
        _semaphore = new Semaphore();
        _rpcStream = new RpcStreamClient(0, this, handler);
    }
    override void start() {
        _rpcStream.connect();
        super.start();
    }
    void stop() {
        _rpcStream.close();
    }
    RpcResponseBody call(T)(string functionName, T param, ubyte[] exData) {
        RpcResponseBody ret;
        if (_rpcStream.isConnected() == false) {
            ret.code = RpcProcCode.SendFailed;
            ret.msg = "connection is not valid";
            return ret;
        }
        else {
            RpcHeadData head;
            RpcContentData content;
            ubyte code = initHeadBody!(T)(functionName, param, exData, head, content);
            ret.code = code;
            if (code != RpcProcCode.Success) {
                ret.msg = "function call encode failed";
            }
            else {
                void callBack(RpcResponseBody response, ubyte[] data, ubyte protocol) {
                    ret.code = response.code;
                    ret.msg = response.msg;
                    ret.exData = response.exData;
                    _semaphore.notify();
                }
                _rpcStream.addRequestCallback(head.clientSeqId, &callBack);
                _rpcStream.writeRpcData(head, content);
                _semaphore.wait(); 
            }
            _rpcStream.removeRequestCallback(head.clientSeqId);
            return ret;
        }
    }
    RpcResponseBody call(T,R)(string functionName, T param, ubyte[] exData, ref R r) {
        RpcResponseBody ret;
        if (_rpcStream.isConnected() == false) {
            ret.code = RpcProcCode.SendFailed;
            ret.msg = "connection is not valid";
            return ret;
        }
        else {
            RpcHeadData head;
            RpcContentData content;
            ubyte code = initHeadBody!(T)(functionName, param, exData, head, content);
            ret.code = code;
            if (code != RpcProcCode.Success) {
                ret.msg = "function call encode failed";
            }
            else {
                void callBack(RpcResponseBody response, ubyte[] data, ubyte protocol) {
                    ret.code = response.code;
                    ret.msg = response.msg;
                    ret.exData = response.exData;
                    if (ret.code == RpcProcCode.Success) {
                        ret.code = RpcCodec.decodeBuffer!(R)(data, protocol, r);
                    }
                    _semaphore.notify();
                }
                _rpcStream.addRequestCallback(head.clientSeqId, &callBack);
                _rpcStream.writeRpcData(head, content);
                _semaphore.wait(); 
            }
            _rpcStream.removeRequestCallback(head.clientSeqId);
            return ret;
        }
    }
    void call(T,R)(string functionName, T param, ubyte[] exData, void delegate(RpcResponseBody response, R r) func) {

        if (_rpcStream.isConnected() == false) {
            RpcResponseBody response;
            response.code = RpcProcCode.SendFailed;
            response.msg = "connection is not valid";
            R r;
            func(response, r);
        }
        else {
            RpcHeadData head;
            RpcContentData content;
            ubyte code = initHeadBody!(T)(functionName, param, exData, head, content);
            if (code != RpcProcCode.Success) {
                RpcResponseBody response;
                response.code = code;
                response.msg = "function call encode failed";
                R r;
                func(response, r);
                _rpcStream.removeRequestCallback(head.clientSeqId);
            }
            else {
                void callBack(RpcResponseBody response, ubyte[] data, ubyte protocol) {
                    if (response.code == RpcProcCode.Success) {
                        R r;
                        response.code = RpcCodec.decodeBuffer!(R)(data, protocol, r);
                        func(response, r);
                        _rpcStream.removeRequestCallback(head.clientSeqId);
                    }
                }
                _rpcStream.addRequestCallback(head.clientSeqId, &callBack);
                _rpcStream.writeRpcData(head, content);
            }
        }
    }
    void call(T)(string functionName, T param, ubyte[] exData, void delegate(RpcResponseBody response) func) {
        if (_rpcStream.isConnected() == false) {
            RpcResponseBody response;
            response.code = RpcProcCode.SendFailed;
            response.msg = "connection is not valid";
            func(response);
        }
        else {
            RpcHeadData head;
            RpcContentData content;
            ubyte code = initHeadBody!(T)(functionName, param, exData, head, content);
            if (code != RpcProcCode.Success) {
                RpcResponseBody response;
                response.code = code;
                response.msg = "function call encode failed";
                func(response);
                _rpcStream.removeRequestCallback(head.clientSeqId);
            }
            else {
                void callBack(RpcResponseBody response, ubyte[] data, ubyte protocol) {
                    if (response.code == RpcProcCode.Success) {
                        func(response);
                        _rpcStream.removeRequestCallback(head.clientSeqId);
                    }
                }
                _rpcStream.addRequestCallback(head.clientSeqId, &callBack);
                _rpcStream.writeRpcData(head, content);
            }
        }
    }
private:
    ubyte initHeadBody(T)(string functionName, T param, ubyte[] exData, ref RpcHeadData head, ref RpcContentData content) {
        ubyte code = RpcCodec.encodeBuffer!(T)(param, _protocol, content.data);
        if (code != RpcProcCode.Success)
            return code;

        head.rpcVersion = RPC_VERSION;
        head.key = RPC_KEY;
        head.secret = RPC_SECRET;
        head.compress = _compress;
        head.protocol = _protocol;
        head.msgLen = cast(ubyte)functionName.length;
        synchronized(this) {
            head.clientSeqId = _clientSeqId++;
        }
        if (exData !is null) {
            head.exDataLen = cast(ushort)exData.length;
            content.exData = exData.dup;
        }
        content.msg = functionName;
        head.dataLen = cast(ushort)content.data.length;

        return RpcProcCode.Success;
    }
private:
    RpcStreamClient _rpcStream;
    ulong _clientSeqId;
    ubyte _protocol;
    ubyte _compress;
    Semaphore _semaphore;
}   