module KissRpc.rpc_send_package_manage;

import KissRpc.rpc_binary_package;
import KissRpc.rpc_package_base;
import KissRpc.rpc_response;
import KissRpc.rpc_request;
import KissRpc.rpc_event_interface;
import KissRpc.rpc_socket_base_interface;
import KissRpc.rpc_capnproto_package;
import KissRpc.unit;
import KissRpc.logs;


import std.datetime;
import core.thread;

import std.stdio;

 class rpc_send_package_manage:Thread
{
	this(rpc_event_interface rpc_event)
	{
		RPC_SYSTEM_TIMESTAMP = Clock.currStdTime().stdTimeToUnixTime!(long)();

		client_event_interface = rpc_event;

		super(&this.thread_run);
		super.start();

	}


	bool add(rpc_request req, bool checkble = true)
	{
		synchronized(this)
		{
			auto stream_binary_packge = new rpc_binary_package(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, req.get_sequence, req.get_nonblock);
			auto capnproto_pack = new rpc_capnproto_package(req);
			
			auto binary_stream = capnproto_pack.to_binary_stream();
			auto send_stream = stream_binary_packge.to_stream(binary_stream);
			
			bool is_ok = req.get_socket.doWrite(cast(byte[]) send_stream);
			
			if(is_ok)
			{
				if(checkble)
				{
					send_pack[req.get_sequence()] = capnproto_pack;
				}

				de_writefln("send binary stream, length:%s", binary_stream.length);
				
			}else
			{
				req.set_status(RESPONSE_STATUS.RS_FAILD);
				client_event_interface.rpc_send_package_event(req);
			}

			return is_ok;
		}
	}

	bool remove(const ulong index)
	{
		synchronized(this)
		{
			return send_pack.remove(index);
		}
	}


	ulong get_wait_response_num()
	{
		return send_pack.length;
	}

protected:

	void thread_run()
	{
			while(this.isRunning())
			{
				synchronized(this)
				{
						RPC_SYSTEM_TIMESTAMP = Clock.currStdTime().stdTimeToUnixTime!(long)();
						
						foreach(k, v; send_pack)
						{
							auto req = v.get_request_data();
							
							if(req.get_timestamp() + req.get_timeout() < RPC_SYSTEM_TIMESTAMP)
							{
								req.set_status(RESPONSE_STATUS.RS_TIMEOUT);
								client_event_interface.rpc_send_package_event(req);
								this.remove(k);
							}
						}
				}
				this.sleep(dur!("msecs")(100));
			}
	}

private:
    rpc_package_base[ulong] send_pack;
	rpc_event_interface client_event_interface;
}
