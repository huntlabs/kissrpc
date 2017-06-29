module KissRpc.IDL.kiss_idl_interface;

import KissRpc.IDL.kiss_idl_message;
import KissRpc.IDL.kiss_idl_service;

import KissRpc.rpc_request;
import KissRpc.rpc_client_impl;
import KissRpc.rpc_client;
import KissRpc.rpc_response;

abstract class rpc_address_book_interface{ 

	this(rpc_client rp_client){ 
		rp_impl = new rpc_client_impl!(rpc_address_book_service)(rp_client); 
	}

	contacts sync_get_contact_list_interface(string account_name, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(account_name);

		rpc_response resp = rp_impl.sync_call(req, bind_func);

		if(resp.get_status == RESPONSE_STATUS.RS_OK){
			contacts ret_contacts;

			resp.pop(ret_contacts);

			return ret_contacts;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bind_func);
		}
	}



	alias rpc_async_get_contact_list_callback = void delegate(contacts);

	void async_get_contact_list_interface(string account_name, rpc_async_get_contact_list_callback rpc_callback, string bind_func = __FUNCTION__){

		auto req = new rpc_request;

		req.push(account_name);

		rp_impl.async_call(req, delegate(rpc_response resp){

			if(resp.get_status == RESPONSE_STATUS.RS_OK){

				contacts ret_contacts;

				resp.pop(ret_contacts);

				rpc_callback(ret_contacts);
			}else{
				throw new Exception("rpc sync call error, function:" ~ bind_func);
			}}, bind_func);
	}



	rpc_client_impl!(rpc_address_book_service) rp_impl;
}


