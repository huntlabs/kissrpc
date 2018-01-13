

module kissrpc.RpcProxy;

import kissrpc.RpcConstant;
import kissrpc.RpcBuild;
import kissrpc.RpcStream;

import std.string;
import std.experimental.logger.core;

class RpcProxy {
public:
    this() {

    }
    void invokerRpcData(string msg, ubyte[] data, ubyte[] exData, ubyte code, ubyte protocol, ulong clientSeqId, bool isRequest , RpcEventHandler handler, RpcStream stream) {
        if (isRequest) {
            invokerRequest(msg, data, exData, protocol, clientSeqId, handler, stream);
        }
        else {
            invokerResponse(code, msg, data, exData, protocol, clientSeqId, handler, stream);
        }
    }

private:

    //处理rpc客户端请求
    void invokerRequest(string functionName, ubyte[] data, ubyte[] exData, ubyte protocol, ulong clientSeqId, RpcEventHandler handler, RpcStream stream) {
        RpcHeadData head;
        head.rpcVersion = RPC_VERSION;
        head.key = RPC_KEY;
        head.secret = RPC_SECRET;
        head.compress = RpcCompress.None;
        head.protocol = protocol;
        head.clientSeqId = clientSeqId;
        
        RpcContentData content;
        
        auto func = getRpcFunction(functionName);
        if (func is null) {
            head.code = RpcProcCode.NoFunctionName;
            head.exDataLen = 0;
            content.msg = "can not find function name : " ~ functionName;
            head.msgLen = cast(ubyte)content.msg.length;
            head.dataLen = cast(ubyte)content.msg.length;
        }
        else {
            head.code = func(data, protocol, content.data, content.msg);
            head.exDataLen = 0;
            head.dataLen = cast(ushort)content.data.length;
            head.msgLen = cast(ubyte)content.msg.length;
        }
        
        //TODO 服务方返回回调.

        stream.writeRpcData(head, content);
    }

    //处理rpc服务端响应
    void invokerResponse(ubyte code, string msg, ubyte[] data, ubyte[] exData, ubyte protocol, ulong clientSeqId, RpcEventHandler handler, RpcStream tcpStream) {
        auto callback = tcpStream.getRequestCallback(clientSeqId); 
        if (callback is null) {
            if (handler) {
                handler(tcpStream, RpcEvent.NotFoundCallBack, "not fond req callback id %s".format(clientSeqId));
            }
        }
        else {
            RpcResponseBody response;
            response.code = code;
            response.msg = msg;
            response.exData = exData;
            callback(response, data, protocol);
        }
    }


}


