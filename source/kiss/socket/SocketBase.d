module kiss.socket.SocketBase;

import KissRpc.Logs;

import std.socket;
import std.conv;

interface SocketBase
{
	bool isOpen();
	bool peek();
	void close();

	bool connect(string host , ushort port);
	bool listen(string ipaddr, ushort port ,int back_log,  bool breuse);

	size_t read(byte[] buf);
	size_t write(byte[] buf);

	void flush();
	int handle();
	bool isAlive();
	void setKeepAlive(int time, int interval);

	Socket accept();
	Address remoteAddress();
	Address localAddress();

	void setOption(T)(SocketOptionLevel level, SocketOption option, T value);
	T getOption(T)(SocketOptionLevel level, SocketOption option);

	string errorString();

	void setSocket(Socket socket);
}

class KissTcpSocket : SocketBase
{
	public:
		bool isOpen()
		{
			return _socket.handle != socket_t.init && this.peek();	
		}

		bool peek()
		{
			byte[] s;
			return _socket.receive(s, SocketFlags.PEEK) == s.length;
		}

		bool connect(string host, ushort port)
		{
			string strPort = to!string(port);
			AddressInfo[] arr = getAddressInfo(host , strPort , AddressInfoFlags.CANONNAME);
			if(arr.length == 0)
			{
				logError(host ~ ":" ~ strPort);
				return false;
			}
			
			_socket = new Socket(arr[0].family , arr[0].type , arr[0].protocol);
			_socket.blocking(false);
			_socket.connect(arr[0].address);
			
			return true;
		}
		
		bool listen(string ipaddr, ushort port, int back_log = 2048,  bool breuse = true)
		{
			string strPort = to!string(port);
			AddressInfo[] arr = getAddressInfo(ipaddr , strPort , AddressInfoFlags.PASSIVE);
			
			if(arr.length == 0)
			{
				logError("getAddressInfo" ~ ipaddr ~ ":" ~ strPort);
				return false;
			}

			_socket = new Socket(arr[0].family , arr[0].type , arr[0].protocol);
			
			uint use = 1;
			
			if(breuse)
			{	
				_socket.setOption(SocketOptionLevel.SOCKET , SocketOption.REUSEADDR , use);
				version(linux)
				{
					//SO_REUSEPORT
					_socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) 15, use);
				}
			}
			
			_socket.bind(arr[0].address);
			_socket.blocking(false);
			_socket.listen(back_log);
			
			return true;
		}


		void close()
		{
			_socket.close();
		}

		size_t read(byte[] buf)
		{
			return _socket.receive(buf);
		}

		size_t write(byte[] buf)
		{
			return _socket.send(buf);
		}

		void flush()
		{
			this.setOption(SocketOptionLevel.SOCKET, SocketOption.KEEPALIVE, 1);
			this.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
		}

		int handle()
		{
			return _socket.handle;
		}
		
		bool isAlive()
		{
			return _socket.isAlive;
		}

		void setKeepAlive(int time, int interval)
		{
			_socket.setKeepAlive(time, interval);
		}
		
		Socket accept()
		{
			return _socket.accept;
		}

		Address remoteAddress()
		{
			return _socket.remoteAddress;
		}
		
		Address localAddress()
		{
			return _socket.localAddress;	
		}
		
		void setOption(T)(SocketOptionLevel level, SocketOption option, T value)
		{
			_socket.setOption(level, option, value);
		}
		
		T getOption(T)(SocketOptionLevel level, SocketOption option)
		{
			T value;
			return _socket.getOption(level, option, value);
		}
		
		string errorString()
		{
			return _socket.getErrorText();
		}
		
		void setSocket(Socket socket)
		{			
			_socket = socket;
		}

	private:
		Socket 	_socket;
}



