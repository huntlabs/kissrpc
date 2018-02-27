




module kissrpc.RpcStream;

import kissrpc.RpcBase;
import kissrpc.RpcProxy;
import kissrpc.RpcUtils;
import kissrpc.RpcConstant; 
import kissrpc.RpcThreadManager;

import kiss.net.TcpStream;
import kiss.event.loop;
import kiss.event.task;
import kiss.net.Timer;

import std.experimental.logger.core;
import std.socket;
import std.conv;
import std.algorithm.comparison;
import std.exception;
import std.stdio;
import std.string;
import std.functional;

alias RpcCallBack = void delegate(RpcResponseBody response, ubyte[] data, ubyte protocol); 
alias RpcEventHandler = void delegate(RpcStream stream, RpcEvent code, string msg); 


//RPC流解析状态
enum RpcParseStatus {
    RecvHead = 0, //读取HEAD
    RecvBody = 1, //读取消息体
} 

class RpcStream : TcpStream {
public:

    static RpcStream createServer(Socket sock, long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        return new RpcStream(sock, streamId, rpcBase, handler);
    }

    static RpcStream createClient(long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        return new RpcStream(streamId, rpcBase, handler);
    }

    this(Socket sock, long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        super(rpcBase.getLoop(), sock);
        _isServer = true;
        init(rpcBase, streamId, handler);
    }


    this(long streamId, RpcBase rpcBase, RpcEventHandler handler) {
        super(rpcBase.getLoop(), AddressFamily.INET);
        _isServer = false;
        init(rpcBase, streamId, handler);
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

    bool connect() {
        return dealWithConnect();
    }

    bool isConnected() {
        return !_isServer && _isConnected;
    }

    

private:

    void init(RpcBase rpcBase, long streamId, RpcEventHandler handler) {
        _rpcBase = rpcBase;
        _streamId = streamId;
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
        setCloseHandle(()@trusted nothrow {
            catchAndLogException((){

            }());
        }); 
        _reconnectTimes = _rpcBase.getSetting(RpcSetting.ConnectCount);
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
        _recvCache.length = _head.exDataLen + _head.msgLen + _head.dataLen;
        if (_recvCache.length == 0) { //空body默认为RPC心跳 TODO
            if (_isServer) {
                //TODO 服务端收到心跳做应答
            }
        }
        else {
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

    void stopTimer(Timer timer) {
        if (timer)
            timer.stop();
    }
    void createTimer(ref Timer timer, int interval, void delegate() func) {
        if (timer is null)
            timer = new Timer(_rpcBase.getLoop());
        else 
            timer.stop();
        timer.setTimerHandle(()@trusted nothrow {
                catchAndLogException((){
                    func();
                }());
            }).start(interval);
    }

    //处理rpc事件
    void doHandlerEvent(RpcEvent event, string msg) @trusted nothrow {
        catchAndLogException((){
            if (_handler)
                _handler(this, event, msg);
            if (event == RpcEvent.ConnectSuccess) {
                _reconnectTimes = _rpcBase.getSetting(RpcSetting.ConnectCount);
                stopTimer(_connectTimeoutTimer);
                stopTimer(_reconnectIntervalTimer);
            }
            else if (event == RpcEvent.ConnectFailed || event == RpcEvent.ConnectTimeout) {
                collectExceptionMsg(eventLoop.deregister(_watcher));
                stopTimer(_connectTimeoutTimer);
                dealWithReconnect();
            }
            else if (event == RpcEvent.WriteFailed) {

            }
        }());
    }

    //处理客户端重连
    void dealWithReconnect() {
        if (_isServer)
            return;
        if (_reconnectTimes == 0)
            return;
        createTimer(_reconnectIntervalTimer, _rpcBase.getSetting(RpcSetting.ConnectInterval), (){
                log("dealWithReconnect");
                if (_reconnectTimes > 0)
                    _reconnectTimes--;
                resetWatcher();
                dealWithConnect();
                _reconnectIntervalTimer.stop();
            });
    }

    //处理客户端连接
    bool dealWithConnect() {
        if (_isServer)
            return false;
        bool enable = watch();
        if (enable) {
            enable = eventLoop().connect(_watcher,parseAddress(_rpcBase.getHost(), _rpcBase.getPort()));
            //连接超时
            if (enable) {
                createTimer(_connectTimeoutTimer, _rpcBase.getSetting(RpcSetting.ConnectTimeout), (){
                    if (!isConnected()){
                        doHandlerEvent(RpcEvent.ConnectTimeout, "connect timeout");
                    }
                    else {
                        _connectTimeoutTimer.stop();
                    }
                });
            }
        }
        return enable;
    }


protected:

    override void onClose(Watcher watcher) nothrow {
        if (_isServer) {
            doHandlerEvent(RpcEvent.Close, "disconnected from client");
        }
        else {
            if (!_isConnected) {
                doHandlerEvent(RpcEvent.ConnectFailed, "connect server failed");
                return;
            }
            else {
                doHandlerEvent(RpcEvent.Close, "disconnected from server");
            }
            _isConnected = false;
        }
        super.onClose(watcher);
    }

    override void onWrite(Watcher watcher) nothrow{
        if (!_isServer && !_isConnected) {
            _isConnected = true;
            doHandlerEvent(RpcEvent.ConnectSuccess, "connect success");
            return; 
        }
        super.onWrite(watcher);
    }

private:
    ubyte _headStructLen;
    bool _isServer;
    long _streamId;
    long _recvCachePos;
    ubyte[] _recvCache;
    bool _isConnected;
    int _reconnectTimes;  //重连剩余次数
    int _reSendTimes;     //重发剩余次数

    RpcBase _rpcBase;
    RpcHeadData _head;
    RpcEventHandler _handler;
    RpcContentData _content; 
    RpcParseStatus _parseStatus;
    RpcCallBack[ulong] _callbackMap;
    Timer _connectTimeoutTimer;    //连接超时 timer
    Timer _reconnectIntervalTimer;  //连接重试 timer
}  