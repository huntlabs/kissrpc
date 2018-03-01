


module kissrpc.RpcStream;

import kissrpc.RpcBase;
import kissrpc.RpcUtils;
import kissrpc.RpcProxy;
import kissrpc.RpcConstant; 
import kissrpc.RpcThreadManager;
import kissrpc.RpcHeartbeatTimer;


import kiss.net.TcpStream;
import kiss.event.loop;
import kiss.event.task;
import kiss.net.Timer;

import std.socket;
import std.algorithm.comparison;
import std.experimental.logger.core;


//RPC流解析状态
enum RpcParseStatus {
    RecvHead = 0, //读取HEAD
    RecvBody = 1, //读取消息体
}

alias RpcCallBack = void delegate(RpcResponseBody response, ubyte[] data, ubyte protocol); 
alias RpcEventHandler = void delegate(RpcStream stream, RpcEvent code, string msg); 


class RpcStream : TcpStream{
public:
    this(long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        _isServer = false;
        init(streamId, rpcBase, handler);
        super(rpcBase.getLoop(), AddressFamily.INET);
    }
    this(Socket sock, long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        _isServer = true;
        init(streamId, rpcBase, handler);
        super(rpcBase.getLoop(), sock);
    }

    //isRequest true rpc调用返回数据, false rpc调用请求数据
    void writeRpcData(RpcHeadData head, RpcContentData content) {

        ubyte[] data;
        encodeHead(head, data);
        encodeBody(content, data);
        
        void tmpWrite() {
            write(new WarpStreamBuffer(data.dup,(in ubyte[] wdata, size_t size) @trusted nothrow {
									catchAndLogException((){
                                        // log("send success len = %s".format(size));
									}());
								}));
        }
        _rpcBase.getLoop().postTask(newTask(&tmpWrite));
    }

    void addRequestCallback(ulong reqId, RpcCallBack cb) {
        synchronized(this) {
            _callbackMap[reqId] = cb;
        }
    }

    RpcCallBack getRequestCallback(ulong reqId) {
        synchronized(this) {
            if (reqId in _callbackMap) {
                return _callbackMap[reqId];
            }
            return null;
        }
    }
    void removeRequestCallback(ulong reqId) {
        synchronized(this) {
            if (reqId in _callbackMap) {
                _callbackMap.remove(reqId);
            }
        }
    }

    void doHandlerEvent(RpcEvent event, string msg) @trusted nothrow {
        catchAndLogException((){
            if (event == RpcEvent.WriteFailed) {

            }
            else if (event == RpcEvent.HeartbeatClose) {
                close();
            }
            if (_handler)
                _handler(this, event, msg);
        }());
    }

    abstract void doBeartbeatTimer() {}

protected:
    override void onClose(Watcher watcher) nothrow { 
        _beartbeatTimer.stop();
        super.onClose(watcher);
    }
    RpcHeadData getHead() {
        return _head;
    }

private:   
    
    void init(long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        _streamId = streamId;
        _rpcBase = rpcBase;
        _handler = handler;

        _recvCachePos = 0;
        _headStructLen = 0;
        _parseStatus = RpcParseStatus.RecvHead;
        _headStructLen += _head.rpcVersion.sizeof;
        _headStructLen += _head.key.sizeof;
        _headStructLen += _head.secret.sizeof;
        _headStructLen += _head.compress.sizeof;
        _headStructLen += _head.protocol.sizeof;
        _headStructLen += _head.exDataLen.sizeof;
        _headStructLen += _head.msgLen.sizeof;
        _headStructLen += _head.dataLen.sizeof;
        _headStructLen += _head.clientSeqId.sizeof;
        _headStructLen += _head.code.sizeof;
        _recvCache.length = _headStructLen;
        
        setReadHandle((in ubyte[] data)@trusted nothrow {
            catchAndLogException((){
                onRead(data);
            }());
        });
        _beartbeatTimer = new RpcHeartbeatTimer();
        _beartbeatTimer.setCallback(() @trusted{
            doBeartbeatTimer();
        });
        rpcBase.addHeartbeatEvent(_beartbeatTimer);
    }

    void onRead(in ubyte[] data) {
        long dataPos = 0;
        while(true) {
            if (data.length == 0) {
                log("RpcStream recv empty data!!!!");
                break;
            }
            bool dataFinish;
            bool cacheFinish;
            copyBuffer(data, dataPos, _recvCache, _recvCachePos, dataFinish, cacheFinish);
            
            if (cacheFinish) {
                if (_parseStatus == RpcParseStatus.RecvHead) { //解析头
                    if (dealWithHead() == false) {
                        close();
                        break;
                    }
                }
                else if (_parseStatus == RpcParseStatus.RecvBody) { //解析消息体
                    decodeBody();
                    dealWithBody();
                }
            }
            if (dataFinish)
                break;
        }
    }

    //处理消息头
    bool dealWithHead() {
        _head = decodeHead(_recvCache);
        //头信息错误直接断开连接
        if (!checkHeadData(_head)) {
            log("check head infomation error!!!");
            doHandlerEvent(RpcEvent.HeadParseError, "head parse error or check key secrect error!");
            return false;
        }
        int nextLen = _head.exDataLen + _head.msgLen + _head.dataLen;
        if (nextLen == 0) { //空body默认为RPC心跳 TODO
            _recvCache.length = _headStructLen; 
            doHandlerEvent(RpcEvent.RecvHeartbeat, _isServer ? "recv client heartbeat request" : "recv server heartbeat response");
        }
        else {
            _recvCache.length = nextLen;
            _parseStatus = RpcParseStatus.RecvBody;
        }
        _recvCachePos = 0;
        return true;
    }

    //处理消息体
    void decodeBody() {
        uint pos = 0;
        for(int i = 0; i < _head.exDataLen; i++)
            _content.exData ~= _recvCache[pos++];
        for(int i = 0; i < _head.dataLen; i++)
            _content.data ~= _recvCache[pos++];


        RpcUtils.readString(_recvCache, pos, _head.msgLen, _content.msg);
        _recvCache.length = _headStructLen;
        _parseStatus = RpcParseStatus.RecvHead;
        _recvCachePos = 0;
    }

    //拷贝数据到缓存 
    void copyBuffer(in ubyte[] src, ref long srcPos, ubyte[] des, ref long desPos, ref bool srcFinish, ref bool desFinish) {
        long copyLen = min(src.length - srcPos, des.length - desPos);
        des[desPos..desPos+copyLen] = src[srcPos..srcPos+copyLen];
        srcPos += copyLen;
        desPos += copyLen;
        desFinish = des.length == desPos;
        srcFinish = src.length == srcPos;
    }

    //初始化头信息
    RpcHeadData decodeHead(ubyte[] data) {
        uint pos = 0;
        RpcHeadData headData;
        RpcUtils.readBytes!(ushort)(data, pos, headData.rpcVersion);
        RpcUtils.readBytes!(ushort)(data, pos, headData.key);
        RpcUtils.readBytes!(ushort)(data, pos, headData.secret);
        RpcUtils.readBytes!(ubyte)(data, pos, headData.compress);
        RpcUtils.readBytes!(ubyte)(data, pos, headData.protocol);
        RpcUtils.readBytes!(ushort)(data, pos, headData.exDataLen);
        RpcUtils.readBytes!(ubyte)(data, pos, headData.msgLen);
        RpcUtils.readBytes!(ushort)(data, pos, headData.dataLen);
        RpcUtils.readBytes!(ulong)(data, pos, headData.clientSeqId);
        RpcUtils.readBytes!(ubyte)(data, pos, headData.code);
        return headData;
    }



    //效验头信息
    bool checkHeadData(RpcHeadData data) {
        if (data.protocol >= RpcProtocol.Max) {
            log("unsupport protocol ",data.protocol);
            return false;
        }
        if (data.compress >= RpcCompress.Max) {
            log("unsupport compress ",data.compress);
            return false;
        }
        //TODO 效验key secret

        return true;
    }

    
    //处理rpc整包数据
    void dealWithBody() {
        RpcProxy proxy = new RpcProxy();
        ubyte[] data;
        ubyte[] exData;
        data = _content.data.dup;
        exData = _content.exData.dup;
        RpcThreadManager.instance.addCallBack(_streamId, newTask(&proxy.invokerRpcData,
                                                                _content.msg, 
                                                                data, 
                                                                exData,
                                                                _head.code,
                                                                _head.protocol, 
                                                                _head.clientSeqId,
                                                                _isServer,
                                                                _handler,
                                                                this));
    }

    //encode head
    void encodeHead(RpcHeadData head, ref ubyte[] data) {
        RpcUtils.writeBytes!(ushort)(data, head.rpcVersion);
        RpcUtils.writeBytes!(ushort)(data, head.key);
        RpcUtils.writeBytes!(ushort)(data, head.secret);
        RpcUtils.writeBytes!(ubyte)(data, head.compress);
        RpcUtils.writeBytes!(ubyte)(data, head.protocol);
        RpcUtils.writeBytes!(ushort)(data, head.exDataLen);
        RpcUtils.writeBytes!(ubyte)(data, head.msgLen);
        RpcUtils.writeBytes!(ushort)(data, head.dataLen);
        RpcUtils.writeBytes!(ulong)(data, head.clientSeqId);
        RpcUtils.writeBytes!(ubyte)(data, head.code);
    }

    void encodeBody(RpcContentData content, ref ubyte[] data) {
        foreach(value; content.exData) {
            data ~= value;
        }
        foreach(value; content.data) {
            data ~= value;
        } 
        foreach(value; cast(ubyte[])content.msg) {
            data ~= value;
        }
    }


protected:
    RpcBase _rpcBase;
    RpcHeartbeatTimer _beartbeatTimer;
private: 
    ubyte _headStructLen;
    long _recvCachePos;
    ubyte[] _recvCache;
    int _reSendTimes;     //重发剩余次数
    bool _isServer;
    long _streamId;

    RpcHeadData _head;
    RpcContentData _content; 
    RpcEventHandler _handler;
    RpcParseStatus _parseStatus;
    RpcCallBack[ulong] _callbackMap;
}