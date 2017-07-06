module KissRpc.IDL.test_rpc_interface;

import KissRpc.IDL.test_rpc_message;
import KissRpc.IDL.test_rpc_service;

import KissRpc.rpc_request;
import KissRpc.rpc_client_impl;
import KissRpc.rpc_client;
import KissRpc.rpc_response;

abstract class rpc_test_interface{ 

	this(rpc_client rp_client){ 
		rp_impl = new rpc_client_impl!(rpc_test_service)(rp_client); 
	}

	user_info get_name_interface(user_info info, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(info);

		rpc_response resp = rp_impl.sync_call(req, bind_func);

		if(resp.get_status == RESPONSE_STATUS.RS_OK){
			user_info ret_user_info;

			resp.pop(ret_user_info);

			return ret_user_info;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bind_func);
		}
	}


	alias rpc_get_name_callback = void delegate(user_info);

	void get_name_interface(user_info info, rpc_get_name_callback rpc_callback, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(info);

		rp_impl.async_call(req, delegate(rpc_response resp){

			if(resp.get_status == RESPONSE_STATUS.RS_OK){

				user_info ret_user_info;

				resp.pop(ret_user_info);

				rpc_callback(ret_user_info);
			}else{
				throw new Exception("rpc sync call error, function:" ~ bind_func);
			}}, bind_func);
	}


	rpc_client_impl!(rpc_test_service) rp_impl;
}


