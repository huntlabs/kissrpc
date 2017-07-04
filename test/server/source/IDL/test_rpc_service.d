module KissRpc.IDL.test_rpc_service;

import KissRpc.IDL.test_rpc_interface;
import KissRpc.IDL.test_rpc_message;

import KissRpc.rpc_server;

class rpc_test_service: rpc_test_interface{

	this(rpc_server rp_server){
		super(rp_server);
	}

	user_info get_name(user_info info){

		user_info user_info_ret = info;


		return user_info_ret;
	}



}



