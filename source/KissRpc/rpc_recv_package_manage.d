module KissRpc.rpc_recv_package_manage;

import KissRpc.rpc_capnproto_payload;
import KissRpc.rpc_binary_package;
import KissRpc.rpc_server_socket;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_socket_base_interface;
import KissRpc.unit;

import std.parallelism;
import std.stdio;
import core.thread;

class capnproto_recv_package
{
	this()
	{
		binary_package = new rpc_binary_package(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, 0);
		hander = new ubyte[binary_package.get_hander_size];
		recv_remain_bytes = hander.length;
	}


	ubyte[] parse(ubyte[] bytes, ref bool is_ok)
	{
		ulong cpy_size = bytes.length > recv_remain_bytes? recv_remain_bytes : bytes.length;
		ulong bytes_pos = 0;

		if(parse_state == 0)
		{
			hander[hander_pos .. hander_pos + cpy_size] = bytes[bytes_pos .. bytes_pos + cpy_size];

			hander_pos += cpy_size;
			bytes_pos  += cpy_size;

			recv_remain_bytes -= cpy_size;

			if(recv_remain_bytes == 0)
			{		
				if(binary_package.from_stream_for_hander(hander))
				{
					payload = new ubyte[binary_package.get_body_size()];
					recv_remain_bytes = payload.length;
					parse_state = 1;

					return this.parse(bytes[bytes_pos .. bytes_pos + (bytes.length - cpy_size)], is_ok);
				}
			}
		}

		if(parse_state == 1 && recv_remain_bytes > 0)
		{		
			payload[payload_pos .. payload_pos + cpy_size] = bytes[bytes_pos .. bytes_pos + cpy_size];

			payload_pos += cpy_size;
			bytes_pos  += cpy_size;
			recv_remain_bytes -= cpy_size;

			if(recv_remain_bytes == 0) 
			{
				is_ok = binary_package.from_stream_for_payload(payload);
			}
		}

		return bytes[bytes_pos .. bytes_pos + (bytes.length-cpy_size)];
	}

	rpc_binary_package get_package()
	{
		return binary_package;
	}

	bool check_hander_valid()
	{
		return binary_package.check_hander_valid;
	}

	bool check_package_valid()
	{
		return binary_package.check_hander_valid && payload_pos == payload.length;
	}

private:
	ubyte[] hander;
	ubyte[] payload;
	int parse_state;

	ulong hander_pos, payload_pos;

	ulong recv_remain_bytes;

	rpc_binary_package binary_package;
}

class rpc_recv_package_manage
{
	this(rpc_socket_base_interface base_socket,rpc_event_interface rpc_delegate)
	{
		rpc_event_delegate = rpc_delegate;
		socket = base_socket;
	}


	void add(ubyte[] bytes)
	{
		 do{
				auto pack = recv_package.get(id, new capnproto_recv_package);
	
				bool parse_ok = false;

				recv_package[id] = pack;
				
				bytes = pack.parse(bytes, parse_ok);
			
				if(parse_ok)
				{
						auto capnproto_pack = pack.get_package();
						
						if(pack.check_hander_valid())
						{
							if(pack.check_package_valid)
							{
								rpc_event_delegate.rpc_recv_package_event(socket, capnproto_pack);
								recv_package.remove(id);
								id++;
							}

						}else
						{
							capnproto_pack.set_status_code(RPC_PACKAGE_STATUS_CODE.RPSC_FAILED);
							recv_package.remove(id);
							rpc_event_delegate.rpc_recv_package_event(socket, capnproto_pack);		
						}
				 }

			}while(bytes.length > 0);
	}

private:
	ulong id;
	capnproto_recv_package[ulong] recv_package;
	rpc_event_interface rpc_event_delegate;
	rpc_socket_base_interface socket;
}
