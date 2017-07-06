module KissRpc.IDL.test_rpc_service;


import KissRpc.IDL.test_rpc_interface;
import KissRpc.IDL.test_rpc_message;

import KissRpc.rpc_client;

class rpc_test_service: rpc_test_interface{

	this(rpc_client rp_client){
		super(rp_client);
	}

	user_info get_name(user_info info){

		user_info ret = super.get_name_interface(info);
		return ret;
	}


	void get_name(user_info info, rpc_get_name_callback rpc_callback){

		super.get_name_interface(info, rpc_callback);
	}


}



