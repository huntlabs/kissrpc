

module kissrpc.RpcWorkerThread;

import kiss.event.task;

import core.thread;
import std.experimental.logger.core;
import std.conv;
import std.exception;
import std.stdio;


class RpcWorkerThread : Thread {
public:
    this() {
        _isRunning = false;
        _taskCount = 0;
        super(&run);
    }
    void start() {
        if (_isRunning) {
            log("RpcWorkerThread has running !");
            return;
        }
        super.start();
    }
    void run() {
        _isRunning = true;
        _threadID = Thread.getThis.id();
        while(_isRunning)
        {
            doTaskList();
            Thread.sleep(50.msecs);
        }
        _threadID = ThreadID.init;
        _isRunning = false;
    }
    void stop() {
        _isRunning = false;
    }
    void addTask(bool MustInQueue = true)(AbstractTask task)
    {
        static if(!MustInQueue) {
            if (isInLoopThread())
            {
                task.job();
                return;
            }
        }
        synchronized (this)
        {
            _taskList.enQueue(task);
        }
    }
    void doTaskList()
    {
        import std.algorithm : swap;

        TaskQueue tmp;
        synchronized (this){
            swap(tmp, _taskList);
        }
        while (!tmp.empty)
        {
            auto fp = tmp.deQueue();
            try
            {
                fp.job();
            }
            catch (Error e){
                collectException({error(e.toString); writeln(e.toString());}());
                import core.stdc.stdlib;
                exit(-1);
            }
        }
    }
    bool isInLoopThread()
    {
        if (!isRunning)
            return true;
        return _threadID == Thread.getThis.id();
    }
private:
    bool _isRunning;
    long _taskCount;
    ThreadID _threadID;
    TaskQueue _taskList;
}




