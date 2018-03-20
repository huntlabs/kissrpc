

module kissrpc.RpcClient;


import kissrpc.RpcBase;
import kissrpc.RpcCodec;
import kissrpc.RpcConstant;
import kissrpc.RpcStream;
import kissrpc.RpcStreamClient;

import kiss.event.loop;

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

    //sync call
    R call(R = void, T ...)(string functionName, ref RpcResponseBody ret, ubyte[] exData, T param) {
        RpcHeadData head;
        RpcContentData content;
        static if (!is(R == void)) {
            R r;
        }

        if (!checkConnected(ret)) {
            static if (!is(R == void)) {
                return r;
            }
            else {
                return;
            }
        }
        if (!checkHeadBodyValid!(T)(functionName,  exData, head, content, ret, param)) {
            static if (!is(R == void)) {
                return r;
            }
            else {
                return;
            }
        }
        doSyncRequest(ret, head, content, (ubyte[] data, ubyte protocol){
                static if (!is(R == void)) {
                    ret.code = RpcCodec!(R).decodeBuffer(data, protocol, r);
                }
            });
        static if (!is(R == void)) {
            return r;
        }
        else {
            return;
        }
    }

    //async call
    void call(R, T ...)(string functionName, ubyte[] exData, void delegate(RpcResponseBody response, R r) func, T param) {
        RpcHeadData head;
        RpcResponseBody ret;
        RpcContentData content;
        R r;
        if (!checkConnected(ret)) {
            func(ret, r);
            return;
        }
        if (!checkHeadBodyValid!(T)(functionName, exData, head, content, ret, param)) {
            func(ret, r);
            return;
        }
        doAsyncRequest(head, content,(ubyte[] data, ubyte protocol, RpcResponseBody response) {
                if (response.code == RpcProcCode.Success) {
                    response.code = RpcCodec!(R).decodeBuffer(data, protocol, r);
                }
                func(response, r);
            });  
    }
    //async call
    void call(T ...)(string functionName, ubyte[] exData, void delegate(RpcResponseBody response) func, T param) {
        RpcHeadData head;
        RpcResponseBody ret;
        RpcContentData content;
        if (!checkConnected(ret)) {
            func(ret);
            return;
        }
        if (!checkHeadBodyValid!(T)(functionName, exData, head, content, ret, param)) {
            func(ret);
            return;
        }
        doAsyncRequest(head, content,(ubyte[] data, ubyte protocol, RpcResponseBody response) {
                func(response);
            });  
        return;
    }



    RpcHeadData getDefaultHead() {
        RpcHeadData head;
        head.rpcVersion = RPC_VERSION;
        head.key = RPC_KEY;
        head.secret = RPC_SECRET;
        head.compress = _compress;
        head.protocol = _protocol;
        synchronized(this) {
            head.clientSeqId = _clientSeqId++;
        } 
        return head;
    }


    
private:
    ubyte initHeadBody(T ...)(string functionName,  ubyte[] exData, ref RpcHeadData head, ref RpcContentData content, T param) {
        static if (param.length == 1) {
            ubyte code = RpcCodec!(T).encodeBuffer(param, _protocol, content.data);
            if (code != RpcProcCode.Success)
                return code;
        }
        else static if (param.length != 0){
            error("rpc params length can only less than one");
        }
 
        head = getDefaultHead();
        head.msgLen = cast(ubyte)functionName.length;
        
        if (exData !is null) {
            head.exDataLen = cast(ushort)exData.length;
            content.exData = exData.dup;
        }
        content.msg = functionName;
        head.dataLen = cast(ushort)content.data.length;
        return RpcProcCode.Success;
    }
    bool checkConnected(ref RpcResponseBody response) {
        if (_rpcStream.isConnected() == false) {
            response.code = RpcProcCode.SendFailed;
            response.msg = "connection is not valid";
            return false;
        }
        return true;
    }

    bool checkHeadBodyValid(T ...)(string functionName, ubyte[] exData, ref RpcHeadData head, ref RpcContentData content, ref RpcResponseBody response, T param) {
        ubyte code = initHeadBody!(T)(functionName, exData, head, content, param);
        response.code = code;
        if (code != RpcProcCode.Success) {
            response.msg = "function call encode failed";
            _rpcStream.removeRequestCallback(head.clientSeqId);
            return false;
        }
        return true;
    }

    void doSyncRequest(ref RpcResponseBody ret, RpcHeadData head, RpcContentData content, void delegate(ubyte[] data, ubyte protocol) decodeFunc = null) {
        void callBack(RpcResponseBody response, ubyte[] data, ubyte protocol) {
            ret.code = response.code;
            ret.msg = response.msg;
            ret.exData = response.exData;
            if (ret.code == RpcProcCode.Success && decodeFunc) {
                decodeFunc(data, protocol);
            }
            _semaphore.notify();
        }
        _rpcStream.addRequestCallback(head.clientSeqId, &callBack);
        _rpcStream.writeRpcData(head, content);
        _semaphore.wait(); 
        _rpcStream.removeRequestCallback(head.clientSeqId);
    }

    void doAsyncRequest(RpcHeadData head, RpcContentData content, void delegate(ubyte[] data, ubyte protocol, RpcResponseBody response) callBackFunc) {
        void callBack(RpcResponseBody response, ubyte[] data, ubyte protocol) {
            if (callBackFunc) 
                callBackFunc(data, protocol, response);
            _rpcStream.removeRequestCallback(head.clientSeqId);
        }
        _rpcStream.addRequestCallback(head.clientSeqId, &callBack);
        _rpcStream.writeRpcData(head, content);    
    }

private:
    RpcStreamClient _rpcStream;
    ulong _clientSeqId;
    ubyte _protocol;
    ubyte _compress;
    Semaphore _semaphore;
}   