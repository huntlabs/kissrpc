module KissRpc.IDL.kiss_idl_interface;

import KissRpc.IDL.kiss_idl_message;
import KissRpc.IDL.kiss_idl_service;

import KissRpc.rpc_server;
import KissRpc.rpc_server_impl;
import KissRpc.rpc_response;
import KissRpc.rpc_request;

abstract class rpc_address_book_interface{ 

	this(rpc_server rp_server){ 
		rp_impl = new rpc_server_impl!(rpc_address_book_service)(rp_server); 
		rp_impl.bind_request_callback("get_contact_list", &this.get_contact_list_interface); 

	}

	void get_contact_list_interface(rpc_request req){

		auto resp = new rpc_response(req);

		string account_name;


		req.pop(account_name);

		contacts ret_contacts;

		ret_contacts = (cast(rpc_address_book_service)this).get_contact_list(account_name);

		resp.push(ret_contacts);

		rp_impl.response(resp);
	}



	rpc_server_impl!(rpc_address_book_service) rp_impl;
}


