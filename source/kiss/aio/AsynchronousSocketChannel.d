/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.aio.AsynchronousSocketChannel;



import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousChannelBase;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.Event;

import std.conv;
import std.socket;

class AsynchronousSocketChannel : AsynchronousChannelBase{


public:

    this(AsynchronousChannelThreadGroup group, AsynchronousChannelSelector sel)
    {
        super(group, sel);
    }

    static open(AsynchronousChannelThreadGroup group, AsynchronousChannelSelector sel)
    {
        return new AsynchronousSocketChannel(group, sel);
    }

    
    void connect(string ip, ushort port, ConnectCompletionHandle handle, void* attachment, bool blocking = false)
    {
        string strPort = to!string(port);
        AddressInfo[] arr = getAddressInfo(ip , strPort , AddressInfoFlags.CANONNAME);
        _socket = new Socket(arr[0].family , arr[0].type , arr[0].protocol);
		_socket.blocking(blocking);
		_socket.connect(arr[0].address);
        setOpen(true);

		this._ip = ip;
		this._port = port;

       if(register(AIOEventType.OP_CONNECTED, cast(void*)handle, attachment, null) == false)
	   {
			handle.failed(attachment);
	   }
    }


	string getIp()
	{
		return _socket.remoteAddress.toHostNameString;
	}

	string getPort()
	{
		return _socket.remoteAddress.toPortString;
	}

    override int validOps(){
        return  (AIOEventType.OP_READED | AIOEventType.OP_WRITEED | AIOEventType.OP_CONNECTED);
    }

private:
	string _ip;
	ushort _port;

}