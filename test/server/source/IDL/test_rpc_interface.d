module KissRpc.IDL.test_rpc_interface;

import KissRpc.IDL.test_rpc_message;
import KissRpc.IDL.test_rpc_service;

import KissRpc.rpc_server;
import KissRpc.rpc_server_impl;
import KissRpc.rpc_response;
import KissRpc.rpc_request;
abstract class rpc_test_interface{ 

	this(rpc_server rp_server){ 
		rp_impl = new rpc_server_impl!(rpc_test_service)(rp_server); 
		rp_impl.bind_request_callback("get_name", &this.get_name_interface); 

	}

	void get_name_interface(rpc_request req){

		auto resp = new rpc_response(req);

		user_info info;


		req.pop(info);

		user_info ret_user_info;

		ret_user_info = (cast(rpc_test_service)this).get_name(info);

		resp.push(ret_user_info);

		rp_impl.response(resp);
	}



	rpc_server_impl!(rpc_test_service) rp_impl;
}


