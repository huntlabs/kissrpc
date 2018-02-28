


module kissrpc.RpcServer;

import kissrpc.RpcBase;
import kissrpc.RpcStream;
import kissrpc.RpcConstant;
import kissrpc.RpcStreamServer;


import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.event.base;
import kiss.event.loop;

import std.stdio;
import core.thread;
import std.experimental.logger.core;
 
class RpcServer : RpcBase{

public:
    this(EventLoop loop, string host, ushort port, RpcEventHandler handler) {
        super(loop, host, port);
        _listener = new TcpListener(loop, AddressFamily.INET);
        _listener.reusePort(true);
        _listener.bind(host, port).listen(1024).setReadHandle((EventLoop loop, Socket socket) @trusted nothrow {
                    catchAndLogException((){
                        synchronized (this) {
                            RpcStreamServer stream = new RpcStreamServer(socket, _streamId++, this, handler);
                            stream.watch();
                            _rpcStreams ~= stream;
                            handler(stream, RpcEvent.NewClientCome, "new client connect");
                        }
                }());
            }).watch;
        writeln("Listen :", _listener.bind.toString);
    }
    void stop() {
        synchronized (this) {
            foreach(value; _rpcStreams) {
                value.close();
            }
        }
    }
private:
    long _streamId;
    TcpListener _listener;
    RpcStreamServer[] _rpcStreams;
}   