module KissRpc.IDL.kiss_idl_service;

import KissRpc.IDL.kiss_idl_interface;
import KissRpc.IDL.kiss_idl_message;

import KissRpc.rpc_server;

class rpc_address_book_service: rpc_address_book_interface{

	this(rpc_server rp_server){
		super(rp_server);
	}

	contacts sync_get_contact_list(string account_name){

		contacts contacts_ret;

		import std.conv;
		import std.stdio;

		contacts_ret.number = 100;
		contacts_ret.user_info_list = new user_info[10];


		foreach(i,ref v; contacts_ret.user_info_list)
		{
			v.phone ~= "135167321"~to!string(i);
			v.age = cast(int)i;
			v.user_name = account_name~to!string(i);
			v.address_list = new string[2];
			v.address_list[0] =  account_name ~ "address1 :" ~ to!string(i);
			v.address_list[1] =  account_name ~ "address2 :" ~ to!string(i);

		}

		return contacts_ret;
	}



	contacts async_get_contact_list(string account_name){

		contacts contacts_ret;

		import std.conv;
		import std.stdio;
		
		contacts_ret.number = 100;
		contacts_ret.user_info_list = new user_info[10];
		
		
		foreach(i,ref v; contacts_ret.user_info_list)
		{
			v.phone ~= "135167321"~to!string(i);
			v.age = cast(int)i;
			v.user_name = account_name~to!string(i);
			v.address_list = new string[2];
			v.address_list[0] =  account_name ~ "address1 :" ~ to!string(i);
			v.address_list[1] =  account_name ~ "address2 :" ~ to!string(i);
			
		}
		
		return contacts_ret;

	}



}



