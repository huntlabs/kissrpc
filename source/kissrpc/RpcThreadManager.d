


module kissrpc.RpcThreadManager;

import kissrpc.RpcWorkerThread;
import kiss.event.task;

import std.parallelism;

class RpcThreadManager {
public: 
    this() {
        int threadNum = totalCPUs * 4;
        for(int i = 0; i < threadNum; i ++) {
            RpcWorkerThread thread = new RpcWorkerThread();
            thread.start();
            _threads ~= thread; 
        }
    }
    @property static RpcThreadManager instance() {
        if (_instance is null) {
            _instance = new RpcThreadManager();
        }
        return _instance;
    }

    void addCallBack(long serverId, AbstractTask cback) {
        _threads[serverId%_threads.length].addTask(cback);
    }
    
private:
    __gshared RpcThreadManager _instance;
    RpcWorkerThread[] _threads;
}