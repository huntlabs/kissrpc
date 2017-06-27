module KissRpc.IDL.kiss-idl_interface;


import KissRpc.IDL.kiss-idl_message;


import KissRpc.rpc_request;
import KissRpc.rpc_client_impl;
import KissRpc.rpc_client;
import KissRpc.rpc_response;


abstract class rpc_hello_interface{ 

	this(rpc_client rp_client){ 
		rp_impl = new rpc_client_impl!(rpc_hello_service)(rp_client); 
	}

	int func_name_sync_interface(string msg, int i, double d, sites site, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(msg, i, d, site.length, site.hander, );

		rpc_response resp = rp_impl.sync_call(req, bind_func);

		if(resp.get_status == RESPONSE_STATUS.RS_OK){
			int ret_int;

			resp.pop(ret_int);

			return ret_int;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bind_func);
		}
	}



	sites save_user_info_interface(string name, user_info info, int num, user_info user, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(name, info.wiget, info.phone, info.age, info.user_name, , num, user.wiget, user.phone, user.age, user.user_name, );

		rpc_response resp = rp_impl.sync_call(req, bind_func);

		if(resp.get_status == RESPONSE_STATUS.RS_OK){
			sites ret_sites;

			resp.pop(ret_sites.length, ret_sites.hander, );

			return ret_sites;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bind_func);
		}
	}



	user_info query_user_info_interface(string name, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(name);

		rpc_response resp = rp_impl.sync_call(req, bind_func);

		if(resp.get_status == RESPONSE_STATUS.RS_OK){
			user_info ret_user_info;

			resp.pop(ret_user_info.wiget, ret_user_info.phone, ret_user_info.age, ret_user_info.user_name, );

			return ret_user_info;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bind_func);
		}
	}



	alias rpc_func_name_async_callback = void delegate(string);

	string func_name_async_interface(string msg, int i, double d, rpc_func_name_async_callback rpc_callback, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(msg, i, d);

		rp_impl.async_call(req, delegate(rpc_response resp){

			if(resp.get_status == RESPONSE_STATUS.RS_OK){

				string ret_string;

				resp.pop(ret_string);

				rpc_callback(ret_string);
			}else{
				throw new Exception("rpc sync call error, function:" ~ bind_func);
			}}, bind_func);
	}



	rpc_client_impl!(rpc_hello_service) rp_impl;
}


class rpc_hello_service: rpc_hello_interface{

	this(rpc_client rp_client){
		super(rp_client);
	}

	int func_name_sync(string msg, int i, double d, sites site){

		int ret = super.func_name_sync_interface(msg, i, d, site);
		return ret;
	}



	sites save_user_info(string name, user_info info, int num, user_info user){

		sites ret = super.save_user_info_interface(name, info, num, user);
		return ret;
	}



	user_info query_user_info(string name){

		user_info ret = super.query_user_info_interface(name);
		return ret;
	}



	string func_name_async(string msg, int i, double d, rpc_func_name_async_callback rpc_callback){

		super.func_name_async_interface(msg, i, d, rpc_callback);
	}



}



abstract class rpc_web_interface{ 

	this(rpc_client rp_client){ 
		rp_impl = new rpc_client_impl!(rpc_web_service)(rp_client); 
	}

	alias rpc_get_net_callback = void delegate(net);

	net get_net_interface(int index, rpc_get_net_callback rpc_callback, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(index);

		rp_impl.async_call(req, delegate(rpc_response resp){

			if(resp.get_status == RESPONSE_STATUS.RS_OK){

				net ret_net;

				resp.pop(ret_net.body_length, ret_net.hander, );

				rpc_callback(ret_net);
			}else{
				throw new Exception("rpc sync call error, function:" ~ bind_func);
			}}, bind_func);
	}



	rpc_client_impl!(rpc_web_service) rp_impl;
}


class rpc_web_service: rpc_web_interface{

	this(rpc_client rp_client){
		super(rp_client);
	}

	net get_net(int index, rpc_get_net_callback rpc_callback){

		super.get_net_interface(index, rpc_callback);
	}



}



