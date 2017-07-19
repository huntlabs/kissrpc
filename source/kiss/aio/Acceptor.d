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
module kiss.aio.Acceptor;

import kiss.socket.SocketBase;

import std.socket;

final package class Acceptor
{
	this()
	{
		// Constructor code
	}

	bool open(string ipaddr, ushort port, int back_log ,  bool breuse)
	{
		_socket = new KissTcpSocket;
		return _socket.listen(ipaddr, port, back_log, breuse);
	}

	Socket accept()
	{
		return _socket.accept();
	}

	void close()
	{
		_socket.close();
	}

	@property
	int fd() 
	{
		return _socket.handle;
	}


	private SocketBase 	_socket;
}

