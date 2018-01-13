


module kissrpc.RpcServer;

import kissrpc.RpcConstant;
import kissrpc.RpcStream;

import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.event.loop;
import kiss.event.base;

import std.stdio;
import core.thread;
import std.experimental.logger.core;
 
class RpcServer {
public:
    this(EventLoop loop, string host, ushort port, RpcEventHandler handler) {
        _loop = loop;
        _listener = new TcpListener(_loop, AddressFamily.INET);
        _listener.bind(host, port).listen(1024).setReadHandle((EventLoop loop, Socket socket) @trusted nothrow {
                    catchAndLogException((){
                        synchronized (this) {
                            RpcStream stream = RpcStream.createServer(_loop, socket, handler, _streamId++);
                            stream.watch();
                            _rpcStreams ~= stream;
                            if (handler) {
                                handler(stream, RpcEvent.NewClientCome, "new client connect");
                            }
                        }
                }());
            }).watch;
        writeln("Listen :", _listener.bind.toString);
    }
    void start() {
        _loop.join();
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
    EventLoop _loop;
    TcpListener _listener;
    RpcStream[] _rpcStreams;
}   