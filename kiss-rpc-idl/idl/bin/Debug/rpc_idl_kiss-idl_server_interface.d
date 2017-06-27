module KissRpc.IDL.kiss-idl_interface;


import KissRpc.IDL.kiss-idl_message;


import KissRpc.rpc_server;
import KissRpc.rpc_server_impl;
import KissRpc.rpc_response;
import KissRpc.rpc_request;


abstract class rpc_hello_interface{ 

	this(rpc_server rp_server){ 
		rp_impl = new rpc_server_impl!(rpc_hello_service)(rp_server); 
		rp_impl.bind_request_callback("func_name_sync", &this.func_name_sync_interface); 

		rp_impl.bind_request_callback("save_user_info", &this.save_user_info_interface); 

		rp_impl.bind_request_callback("query_user_info", &this.query_user_info_interface); 

		rp_impl.bind_request_callback("func_name_async", &this.func_name_async_interface); 

	}

	void func_name_sync_interface(rpc_request req){

		auto resp = new rpc_response(req);

		string msg;
		sites site;
		double d;
		int i;


		req.pop(msg, i, d, site.length, site.hander);

		(cast(rpc_hello_service)this).func_name_sync(msg, i, d, site);

		int ret_int;

		ret_int = (cast(rpc_hello_service)this).func_name_sync(msg, i, d, site);

		resp.push(ret_int);

		rp_impl.response(resp);
	}



	void save_user_info_interface(rpc_request req){

		auto resp = new rpc_response(req);

		string name;
		user_info user;
		int num;
		user_info info;


		req.pop(name, info.wiget, info.phone, info.age, info.user_name num, user.wiget, user.phone, user.age, user.user_name);

		(cast(rpc_hello_service)this).save_user_info(name, info, num, user);

		sites ret_sites;

		ret_sites = (cast(rpc_hello_service)this).save_user_info(name, info, num, user);

		resp.push(ret_sites.length, ret_sites.hander);

		rp_impl.response(resp);
	}



	void query_user_info_interface(rpc_request req){

		auto resp = new rpc_response(req);

		string name;


		req.pop(name);

		(cast(rpc_hello_service)this).query_user_info(name);

		user_info ret_user_info;

		ret_user_info = (cast(rpc_hello_service)this).query_user_info(name);

		resp.push(ret_user_info.wiget, ret_user_info.phone, ret_user_info.age, ret_user_info.user_name);

		rp_impl.response(resp);
	}



	void func_name_async_interface(rpc_request req){

		auto resp = new rpc_response(req);

		string msg;
		double d;
		int i;


		req.pop(msg, i, d);

		(cast(rpc_hello_service)this).func_name_async(msg, i, d);

		string ret_string;

		ret_string = (cast(rpc_hello_service)this).func_name_async(msg, i, d);

		resp.push(ret_string);

		rp_impl.response(resp);
	}



	rpc_server_impl!(rpc_hello_service) rp_impl;
}


class rpc_hello_service: rpc_hello_interface{

	this(rpc_server rp_server){
		super(rp_server);
	}

	int func_name_sync(string msg, int i, double d, sites site){


		return int;
	}



	sites save_user_info(string name, user_info info, int num, user_info user){


		return sites;
	}



	user_info query_user_info(string name){


		return user_info;
	}



	string func_name_async(string msg, int i, double d){


		return string;
	}



}



abstract class rpc_web_interface{ 

	this(rpc_server rp_server){ 
		rp_impl = new rpc_server_impl!(rpc_web_service)(rp_server); 
		rp_impl.bind_request_callback("get_net", &this.get_net_interface); 

	}

	void get_net_interface(rpc_request req){

		auto resp = new rpc_response(req);

		int index;


		req.pop(index);

		(cast(rpc_web_service)this).get_net(index);

		net ret_net;

		ret_net = (cast(rpc_web_service)this).get_net(index);

		resp.push(ret_net.body_length, ret_net.hander);

		rp_impl.response(resp);
	}



	rpc_server_impl!(rpc_web_service) rp_impl;
}


class rpc_web_service: rpc_web_interface{

	this(rpc_server rp_server){
		super(rp_server);
	}

	net get_net(int index){


		return net;
	}



}



