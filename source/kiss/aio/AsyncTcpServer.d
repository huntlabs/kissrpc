/*
 * Kiss - A simple base net library
 *
 * Copyright (C) 2017 Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module kiss.aio.AsyncTcpServer;

import kiss.event.Event;
import kiss.event.Poll;
import kiss.aio.Acceptor;
import kiss.aio.AsyncTcpBase;
import kiss.event.GroupPoll;

import std.socket;


final class AsyncTcpServer(T , A...): Event
{

	this(Poll poll , A args)
	{
		_args = args;
		_poll = poll;
		_acceptor = new Acceptor();
	}

	bool open(string ipaddr, ushort port, int back_log = 2048 ,  bool breuse = true)
	{

		if(!_acceptor.open(ipaddr , port , back_log , breuse))
		{
			return false;
		}

		_poll.addEvent(this , _acceptor.fd ,  IOEventType.IO_EVENT_READ);

		return true;
	}


	void close()
	{
		_isreadclose = true;
	}

	protected bool isReadyClose()
	{
		return _isreadclose;
	}


	protected bool onWrite()
	{
		return true;
	}

	protected bool onRead()
	{
		T t = new T(_poll , _args);
		Socket socket = _acceptor.accept();
		socket.blocking(false);
		t.setSocket(socket);

		return t.open();
	}

	protected bool onClose()
	{
		_acceptor.close();
		return true;
	}

	protected bool	   			_isreadclose = false;
	protected Poll	   			_poll;
	protected Acceptor 			_acceptor;
	protected A					_args;
}

