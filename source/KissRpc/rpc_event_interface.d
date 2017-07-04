module KissRpc.rpc_event_interface;

import KissRpc.rpc_binary_package;
import KissRpc.rpc_socket_base_interface;
import KissRpc.rpc_response;

enum SOCKET_STATUS{
	SE_CONNECTD,
	SE_DISCONNECTD,
	SE_WRITE_FAILED,
	SE_READ_FAILED,
	SE_LISTEN_FAILED,
}

interface rpc_event_interface
{
	void rpc_recv_package_event(rpc_socket_base_interface socket, rpc_binary_package recv_package);
	void rpc_send_package_event(rpc_response resp);

	void socket_event(rpc_socket_base_interface socket,const SOCKET_STATUS status, const string status_str);
}
