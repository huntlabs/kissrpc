module KissRpc.IDL.kiss_idl_service;


import KissRpc.IDL.kiss_idl_interface;
import KissRpc.IDL.kiss_idl_message;

import KissRpc.rpc_client;

class rpc_address_book_service: rpc_address_book_interface{

	this(rpc_client rp_client){
		super(rp_client);
	}

	contacts get_contact_list(string account_name){

		contacts ret = super.get_contact_list_interface(account_name);
		return ret;
	}


	void get_contact_list(string account_name, rpc_get_contact_list_callback rpc_callback){

		super.get_contact_list_interface(account_name, rpc_callback);
	}


}



