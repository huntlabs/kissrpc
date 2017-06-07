module KissRpc.rpc_server;

import KissRpc.rpc_request;
import KissRpc.unit;
import KissRpc.rpc_response;
import KissRpc.rpc_binary_package;
import KissRpc.rpc_capnproto_package;
import KissRpc.rpc_server_socket;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_package_base;
import KissRpc.rpc_socket_base_interface;
import KissRpc.rpc_send_package_manage;
import KissRpc.logs;

import kiss.event.GroupPoll;
import kiss.aio.AsyncGroupTcpServer;
import std.stdio;

alias request_callback = void delegate(rpc_request);

class rpc_server:rpc_event_interface{

	this(server_socket_event_interface socket_event)
	{
		server_socket_event = socket_event;
		send_pack_manage = new rpc_send_package_manage(this);
	}

	void bind(string class_name, string func_name)
	{
		string key = class_name ~ "." ~ func_name;
		rpc_callback_map[key] = (rpc_request){};
		
		de_writefln("rpc server bind:%s", key);
	}
	
	void bind_callback(string func_name, request_callback callback)
	{
		rpc_callback_map[func_name] = callback;
		de_writefln("rpc server bind callback:%s, addr:%s",func_name, callback);
	}

	bool rpc_response_remote_call(rpc_response resp)
	{
		de_writefln("rpc response remote call, func:%s", resp.get_call_func_name);
		return 	send_pack_manage.add(resp, false);
	}


	void rpc_recv_package_event(rpc_socket_base_interface socket, rpc_binary_package pack)
	{
		de_writefln("server recv package event, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s", 
					pack.get_hander_size, pack.get_packge_size, pack.get_version, pack.get_sequence_id, pack.get_body_size);

		if(pack.get_status_code != RPC_PACKAGE_STATUS_CODE.RPSC_OK)
		{
			log_warning("server recv binary package is failed, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s, status code:%s", 
				pack.get_hander_size, pack.get_packge_size, pack.get_version, pack.get_sequence_id, pack.get_body_size, pack.get_status_code);
		
		}else
		{
			rpc_package_base package_base;
			
			switch(pack.get_serialized_type)
			{
				case RPC_PACKAGE_PROTOCOL.TPP_JSON:break;
				case RPC_PACKAGE_PROTOCOL.TPP_XML: break;
				case RPC_PACKAGE_PROTOCOL.TPP_PROTO_BUF: break;
				case RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF:  break;
				case RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF: package_base = new rpc_capnproto_package(socket, pack.get_payload()); break;
					
				default:
					log_warning("unpack serialized type is failed!, type:%d", pack.get_serialized_type());
			}
			
			auto rpc_req = package_base.get_request_data();
			rpc_req.set_sequence(pack.get_sequence_id());
			rpc_req.set_nonblock(pack.get_nonblock());

			de_writefln("rpc client request call, func:%s, arg num:%s", rpc_req.get_call_func_name(), rpc_req.get_args_num());
			
			rpc_callback_map[rpc_req.get_call_func_name](rpc_req);
		}
	}

	void rpc_send_package_event(rpc_response rpc_resp)
	{
		switch(rpc_resp.get_status)
		{
			case RESPONSE_STATUS.RS_TIMEOUT:
				log_warning("response timeout, func:%s, start time:%s, time:%s, sequence:%s", rpc_resp.get_call_func_name, rpc_resp.get_timestamp, rpc_resp.get_timeout, rpc_resp.get_sequence);
				break;
				
			case RESPONSE_STATUS.RS_FAILD:
				log_warning("request failed, func:%s, start time:%s, time:%s, sequence:%s", rpc_resp.get_call_func_name, rpc_resp.get_timestamp, rpc_resp.get_timeout, rpc_resp.get_sequence);
				break;
				
			default:
				log_warning("rpc send package event is fatal!!, event type error!");
		}
	}

	void socket_event(rpc_socket_base_interface socket, const SOCKET_STATUS status,const string status_str)
	{
		log_info("server socket status:%s", status_str);

		switch(status)
		{
			case SOCKET_STATUS.SE_LISTEN_FAILED: server_socket_event.listen_failed(status_str); break;
			case SOCKET_STATUS.SE_CONNECTD: server_socket_event.inconming(socket); break;
			case SOCKET_STATUS.SE_DISCONNECTD:server_socket_event.disconnectd(socket); break;
			case SOCKET_STATUS.SE_READ_FAILED: server_socket_event.read_failed(socket); break;
			case SOCKET_STATUS.SE_WRITE_FAILED: server_socket_event.write_failed(socket); break;

			default:
				log_error("server socket status is fatal!!", status_str);
		}
	}

	bool listen(string ip, ushort port, GroupPoll!() poll)
	{
		auto server_poll = new AsyncGroupTcpServer!(rpc_server_socket, rpc_event_interface)(poll, this);
		return server_poll.open(ip , port);
	}

private:
	rpc_send_package_manage send_pack_manage;

	server_socket_event_interface server_socket_event;
	request_callback[string] rpc_callback_map;
}