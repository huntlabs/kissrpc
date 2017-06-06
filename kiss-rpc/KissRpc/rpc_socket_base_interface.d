module KissRpc.rpc_socket_base_interface;

import std.socket;

interface rpc_socket_base_interface
{
	bool doWrite(byte[] data);

	int getFd();

	string getIp();

	string getPort();

	void disconnect();
}

interface client_socket_event_interface
{
	void connectd(rpc_socket_base_interface socket);
	void disconnectd(rpc_socket_base_interface socket);
	void write_failed(rpc_socket_base_interface socket);
	void read_failed(rpc_socket_base_interface socket);
}

interface server_socket_event_interface
{
	void listen_failed(const string str);
	void inconming(rpc_socket_base_interface socket);
	void disconnectd(rpc_socket_base_interface socket);
	void write_failed(rpc_socket_base_interface socket);
	void read_failed(rpc_socket_base_interface socket);
}