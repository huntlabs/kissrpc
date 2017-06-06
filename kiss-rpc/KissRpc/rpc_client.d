module KissRpc.rpc_client;

import KissRpc.rpc_request;
import KissRpc.unit;
import KissRpc.rpc_response;
import KissRpc.rpc_binary_package;
import KissRpc.rpc_capnproto_package;
import KissRpc.rpc_client_socket;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_package_base;
import KissRpc.rpc_socket_base_interface;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_send_package_manage;

import kiss.event.GroupPoll;
import kiss.aio.AsyncTcpServer;

import std.parallelism;
import std.stdio;


alias  repons_callback =  void delegate(rpc_response);


class rpc_client:rpc_event_interface{

	this(client_socket_event_interface socket_event)
	{
		client_socket_event = socket_event;
		send_pack_manage = new rpc_send_package_manage(this);
		defaultPoolThreads = RPC_CLIENT_DEFAULT_THREAD_POOL;
	}
	
	void bind(string class_name, string func_name)
	{
		string key = class_name ~ "." ~ func_name;
		de_writefln("rpc client bind:%s", key);
	}

	void bind_callback(string func_name, repons_callback callback)
	{
		rpc_callback_map[func_name] = callback;
	}

	
	bool request_remote_call(rpc_request req)
	{	
		pack_message_count++;
		req.set_sequence(pack_message_count);
		req.set_socket(client_socket);

		de_writefln("rpc client request remote call:%s", req.get_call_func_name());
		return send_pack_manage.add(req);
	}

	void rpc_recv_package_event(rpc_socket_base_interface socket, rpc_binary_package pack)
	{

		if(send_pack_manage.remove(pack.get_sequence_id))
		{
			de_writefln("client recv package event, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s", 
				pack.get_hander_size, pack.get_packge_size, pack.get_version, pack.get_sequence_id, pack.get_body_size);

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

			auto rpc_resp = package_base.get_response_data();

			rpc_resp.set_sequence(pack.get_sequence_id());
			rpc_resp.set_nonblock(pack.get_nonblock());

			if(pack.get_status_code != RPC_PACKAGE_STATUS_CODE.RPSC_OK)
			{
				log_warning("server recv binary package is failed, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s, status code:%s", 
					pack.get_hander_size, pack.get_packge_size, pack.get_version, pack.get_sequence_id, pack.get_body_size, pack.get_status_code);
				
				rpc_resp.set_status(RESPONSE_STATUS.RS_FAILD);
				
			}else
			{
				rpc_resp.set_status(RESPONSE_STATUS.RS_OK);	
				de_writefln("rpc server response call, func:%s, arg num:%s", rpc_resp.get_call_func_name(), rpc_resp.get_args_num());			
			}
			
			if(pack.get_nonblock)
			{
				de_writefln("async call form rpc server response, func:%s, arg num:%s", rpc_resp.get_call_func_name(), rpc_resp.get_args_num());			
			}else
			{
				de_writefln("sync call form rpc server response, func:%s, arg num:%s", rpc_resp.get_call_func_name(), rpc_resp.get_args_num());			
			}

			synchronized(this)
			{
				rpc_callback_map[rpc_resp.get_call_func_name](rpc_resp);
			}	

		}else
		{
			log_warning("Accept error, client recv response failed, package is timeout!!!, hander len:%s, package size:%s, ver:%s, sequence id:%s, body size:%s", 
				pack.get_hander_size, pack.get_packge_size, pack.get_version, pack.get_sequence_id, pack.get_body_size);
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

		synchronized(this)
		{
			rpc_callback_map[rpc_resp.get_call_func_name](rpc_resp);
		}
	}


	void socket_event(rpc_socket_base_interface socket, const SOCKET_STATUS status,const string status_str)
	{
		log_info("client socket status info:%s", status_str);
		switch(status)
		{
			case SOCKET_STATUS.SE_CONNECTD:
				 auto t = task(&client_socket_event.connectd, socket); 
				 taskPool.put(t);
				 break;

			case SOCKET_STATUS.SE_DISCONNECTD: 
				auto t = task(&client_socket_event.disconnectd, socket); 
				taskPool.put(t);
				break;
			
			case SOCKET_STATUS.SE_READ_FAILED : 
				 auto t = task(&client_socket_event.read_failed, socket); 
				 taskPool.put(t);
				 break;

			case SOCKET_STATUS.SE_WRITE_FAILED: 
				auto t = task(&client_socket_event.write_failed, socket); 
				taskPool.put(t);
				break;
		
			default:
				log_error("client socket status is fatal!!", status_str);
				return;
		}

	}

	void connect(string ip, ushort port, GroupPoll!() poll)
	{
		client_socket = new rpc_client_socket(ip, port, poll, this);
	}

	ulong get_wait_response_num()
	{
		return send_pack_manage.get_wait_response_num;
	}

	
private:
	rpc_send_package_manage send_pack_manage;

	repons_callback[string] rpc_callback_map;

	ulong pack_message_count;

	rpc_client_socket client_socket;
	client_socket_event_interface client_socket_event;
}
