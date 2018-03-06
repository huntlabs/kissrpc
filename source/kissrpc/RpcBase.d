

module kissrpc.RpcBase;

// import kissrpc.RpcStreamBase;
import kissrpc.RpcConstant;
import kissrpc.RpcHeartbeatTimer;

import kiss.event.loop;
import kiss.net.Timer;
import kiss.timingwheel;


import std.experimental.logger.core;



class RpcBase {
public:
    this(EventLoop loop, string host, ushort port) {
        _loop = loop;
        _host = host;
        _port = port;
        _isRunning = false;
        init();
    }

    void init() {
        initSetting();
        initHeartbeatTimer();
    }

    void start() {
        _isRunning = true;
        _loop.join();
    }
    //获取配置
    int getSetting(RpcSetting type) {
        return _defaultSetting[type];
    }
    //修改设置
    bool modfSetting(RpcSetting type, int value) {
        if (_isRunning && (type == RpcSetting.HeartbeatInterval)) {
            return false;
        }
        _defaultSetting[type] = value;
        return true;
    }
    //增加心跳包事件
    void addHeartbeatEvent(RpcHeartbeatTimer tm) {
        _wheel.addNewTimer(cast(WheelTimer)tm);
    }

    EventLoop getLoop() {
        return _loop;
    }
    string getHost() {
        return _host;
    }
    ushort getPort() {
        return _port;
    }
private:
    //初始化默认配置
    void initSetting() {
        _defaultSetting[RpcSetting.ConnectCount] = -1;       //重连次数  (-1:一直重连)
        _defaultSetting[RpcSetting.ConnectTimeout] = 1000;  //连接超时时间 (单位ms)
        _defaultSetting[RpcSetting.ConnectInterval] = 5000; //重连间隔  (单位ms)
        _defaultSetting[RpcSetting.ReSendTimeout] = 30000;  //发送超时时间 (单位ms)
        _defaultSetting[RpcSetting.ReSendCount] = 0;        //发送失败重发次数  (-1:一直重发)
        _defaultSetting[RpcSetting.ReSendInterval] = 1000;  //发送失败重发间隔 (单位ms)
        _defaultSetting[RpcSetting.HeartbeatInterval] = 10000; //心跳包间隔时间  (单位ms)
        _defaultSetting[RpcSetting.HeartbeatTimeoutCount] = 3; //连续几次未收到心跳包断开连接
    }
    //初始化心跳timer
    void initHeartbeatTimer() {
        const uint interval = 1000;
        _wheel = new TimingWheel(cast(uint)_defaultSetting[RpcSetting.HeartbeatInterval]/interval);
        _heartbeatTimer = new Timer(_loop);
        _heartbeatTimer.setTimerHandle(()@trusted nothrow {
                    catchAndLogException((){
                        _wheel.prevWheel();
                    }());
                }).start(interval);
    }   
protected:
    string _host;
    ushort _port;
    EventLoop _loop;
    Timer _heartbeatTimer;
    TimingWheel _wheel; 
    int[RpcSetting.Max] _defaultSetting;
    bool _isRunning;
}