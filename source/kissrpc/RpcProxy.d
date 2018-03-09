

module kissrpc.RpcProxy;

import kissrpc.RpcBuild;
import kissrpc.RpcConstant;
import kissrpc.RpcStreamClient;
import kissrpc.RpcStreamServer;
import kissrpc.RpcThreadManager;

import kiss.event.task;

import std.string;
import std.experimental.logger.core;

class RpcProxy {
public:

    //处理rpc客户端请求
    static void invokerRequest(string functionName, ubyte[] data, ubyte[] exData, ubyte protocol, ulong clientSeqId, RpcStreamServer stream) {
        RpcHeadData head;
        head.rpcVersion = RPC_VERSION;
        head.key = RPC_KEY;
        head.secret = RPC_SECRET;
        head.compress = RpcCompress.None;
        head.protocol = protocol;
        head.clientSeqId = clientSeqId;
        
        RpcContentData content;
        foreach(value; exData) { content.exData ~= value; }
        
        auto func = getRpcFunction(functionName);
        if (func is null) {
            head.code = RpcProcCode.NoFunctionName;
            head.exDataLen = cast(ushort)content.exData.length;
            content.msg = "can not find function name : " ~ functionName;
            head.msgLen = cast(ubyte)content.msg.length;
            head.dataLen = cast(ubyte)content.msg.length;
            stream.writeRpcData(head, content);
        }
        else {
            void tmpCallback() {
                head.code = func(data, protocol, content.data, content.msg, content.exData);
                head.exDataLen = cast(ushort)content.exData.length;
                head.dataLen = cast(ushort)content.data.length;
                head.msgLen = cast(ubyte)content.msg.length;
                stream.writeRpcData(head, content);
            }
            RpcThreadManager.instance.addCallBack(stream.getStreamId(), newTask(&tmpCallback));
        }
    }

    //处理rpc服务端响应
    static void invokerResponse(string msg, ubyte[] data, ubyte[] exData, ubyte protocol, ulong clientSeqId, RpcStreamClient stream, ubyte code) {
        auto callback = stream.getRequestCallback(clientSeqId); 
        if (callback is null) {
            stream.doHandlerEvent(RpcEvent.NotFoundCallBack, "not fond req callback id %s".format(clientSeqId));
        }
        else {
            void tmpCallback() {
                RpcResponseBody response;
                response.code = code;
                response.msg = msg;
                response.exData = exData.dup;
                callback(response, data.dup, protocol);
            }
            RpcThreadManager.instance.addCallBack(stream.getStreamId(), newTask(&tmpCallback));
        }
    }


}


