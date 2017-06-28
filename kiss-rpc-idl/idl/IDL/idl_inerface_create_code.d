module IDL.idl_inerface_create_code;

import std.array : appender;
import std.format;
import std.regex;
import std.stdio;

import IDL.idl_parse_interface;
import IDL.idl_struct_create_code;
import IDL.idl_unit;
import IDL.idl_symbol;


class idl_function_arg_code
{
	static string create_server_code(function_arg function_inerface)
	{
		auto strings = appender!string();
		
		auto dlang_var_name = idl_dlang_variable.get(function_inerface.type_name, null);
		
		if(dlang_var_name == null)
		{
			auto dlang_struct_name = idl_struct_list.get(function_inerface.type_name, null);

			if(dlang_struct_name is null)
			{
				throw new Exception("not parse symbol for struct name: " ~ function_inerface.type_name);
			}
		}

		formattedWrite(strings, "\t\t%s %s;\n", function_inerface.type_name, function_inerface.var_name);

		return strings.data;
	}


	static string create_client_code(function_arg function_inerface)
	{
		auto strings = appender!string();
		
		auto dlang_var_name = idl_dlang_variable.get(function_inerface.type_name, null);
		
		if(dlang_var_name == null)
		{
			auto dlang_struct_name = idl_struct_list.get(function_inerface.type_name, null);
			
			if(dlang_struct_name is null)
			{
				throw new Exception("not parse symbol for struct name: " ~ function_inerface.type_name);
			}
		}
		
		formattedWrite(strings, "\t\t %s %s;\n", function_inerface.type_name, function_inerface.var_name);
		
		return strings.data;
	}
}

class idl_function_attr_code
{
	static string create_server_interface_code(function_attr function_attr_interface, string inerface_name)
	{
		auto strings = appender!string();

		formattedWrite(strings, "\tvoid %s_interface(rpc_request req){\n\n", function_attr_interface.func_name);
		formattedWrite(strings, "\t\tauto resp = new rpc_response(req);\n\n");

		foreach(k,v ;function_attr_interface.func_arg_map)
		{
			formattedWrite(strings, idl_function_arg_code.create_server_code(v));
		}
		
		formattedWrite(strings, "\n\n");
		
		auto func_args_strirngs = appender!string();

		for(int i = 0; i < function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length-1)
				formattedWrite(func_args_strirngs, "%s", v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s, ", v.get_var_name);
		}
		
		formattedWrite(strings, "\t\treq.pop(%s);\n\n", replaceAll(func_args_strirngs.data, regex(`\,\s*\,`), ", "));
	
		func_args_strirngs = appender!string();

		for(int i = 0; i< function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length -1 )
				formattedWrite(func_args_strirngs, "%s", v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s, ", v.get_var_name);
		}



		formattedWrite(strings, "\t\t%s %s;\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.ret_value.get_var_name);

		formattedWrite(strings, "\t\t%s = (cast(rpc_%s_service)this).%s(%s);\n\n", function_attr_interface.ret_value.get_var_name, inerface_name, function_attr_interface.get_func_name, func_args_strirngs.data);

		func_args_strirngs = appender!string();
		formattedWrite(func_args_strirngs, "%s", function_attr_interface.ret_value.get_var_name);

		formattedWrite(strings, "\t\tresp.push(%s);\n\n", replaceAll(func_args_strirngs.data, regex(`\,\s*\,|\,\s$`), ""));
		formattedWrite(strings, "\t\trp_impl.response(resp);\n");

		formattedWrite(strings, "\t}\n\n\n\n");
		
		return strings.data;
	}
	
	static string create_server_service_code(function_attr function_attr_interface)
	{
		auto strings = appender!string();
		
		auto func_args_strirngs = appender!string();
		
		for(int i = 0; i< function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length -1 )
				formattedWrite(func_args_strirngs, "%s %s", v.get_type_name, v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s %s, ", v.get_type_name, v.get_var_name);
		}

		formattedWrite(strings, "\t%s %s(%s){\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.func_name, func_args_strirngs.data);
		formattedWrite(strings, "\t\t%s %s_ret;\n\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.ret_value.get_type_name);
		formattedWrite(strings, "\t\treturn %s_ret;\n\t}\n\n\n\n", function_attr_interface.ret_value.get_type_name);

		return strings.data;
	}



	static string create_client_service_code(function_attr function_attr_interface)
	{
		auto strings = appender!string();
		
		auto func_args_strirngs = appender!string();
		
		for(int i = 0; i< function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length -1 )
				formattedWrite(func_args_strirngs, "%s %s", v.get_type_name, v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s %s, ", v.get_type_name, v.get_var_name);
		}

		auto func_values_args_strirngs = appender!string();

		for(int i = 0; i< function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length -1 )
				formattedWrite(func_values_args_strirngs, "%s", v.get_var_name);
			else
				formattedWrite(func_values_args_strirngs, "%s, ", v.get_var_name);
		}

		if(function_attr_interface.flag == SYMBOL_SYNC)
		{
			formattedWrite(strings, "\t%s %s(%s){\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.func_name, func_args_strirngs.data);

			formattedWrite(strings, "\t\t%s ret = super.%s_interface(%s);\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.func_name, func_values_args_strirngs.data);
			formattedWrite(strings, "\t\treturn ret;\n");
		
		}else if(function_attr_interface.flag == SYMBOL_ASYNC)
		{
			formattedWrite(strings, "\tvoid %s(%s, rpc_%s_callback rpc_callback){\n\n", 
				 function_attr_interface.func_name, func_args_strirngs.data, function_attr_interface.func_name);

			formattedWrite(strings, "\t\tsuper.%s_interface(%s, rpc_callback);\n", function_attr_interface.func_name, func_values_args_strirngs.data);

		}else{
			throw new Exception("function call method is failed:%s, method:"~ function_attr_interface.flag);
		}

		formattedWrite(strings, "\t}\n\n\n\n");

		return strings.data;
	}



	static string create_client_interface_code(function_attr function_attr_interface, string inerface_name)
	{
		auto strings = appender!string();

		auto func_args_strirngs = appender!string();
		
		for(int i = 0; i< function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length -1 )
				formattedWrite(func_args_strirngs, "%s %s", v.get_type_name, v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s %s, ", v.get_type_name, v.get_var_name);
		}

		auto func_args_struct_strirngs = appender!string();
		
		for(int i = 0; i < function_attr_interface.func_arg_map.length; i++)
		{
			auto v = function_attr_interface.func_arg_map[i];
			
			if(i == function_attr_interface.func_arg_map.length-1)
				formattedWrite(func_args_struct_strirngs, "%s", v.get_var_name);
			else
				formattedWrite(func_args_struct_strirngs, "%s, ", v.get_var_name);
		}


		if(function_attr_interface.flag == SYMBOL_SYNC)
		{
			formattedWrite(strings, "\t%s %s_interface(%s, string bind_func = __FUNCTION__){\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.func_name, func_args_strirngs.data);
			
			formattedWrite(strings, "\t\tauto req = new rpc_request;\n\n");

			formattedWrite(strings, "\t\treq.push(%s);\n\n", replaceAll(func_args_struct_strirngs.data, regex(`\,\s*\,`), ", "));

			formattedWrite(strings, "\t\trpc_response resp = rp_impl.sync_call(req, bind_func);\n\n");
			formattedWrite(strings, "\t\tif(resp.get_status == RESPONSE_STATUS.RS_OK){\n");
			formattedWrite(strings, "\t\t\t%s %s;\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.ret_value.get_var_name);

			formattedWrite(strings, "\t\t\tresp.pop(%s);\n\n", function_attr_interface.ret_value.get_var_name);

			formattedWrite(strings, "\t\t\treturn %s;\n\t\t}else{\n", function_attr_interface.ret_value.get_var_name);
			formattedWrite(strings, "\t\t\tthrow new Exception(\"rpc sync call error, function:\" ~ bind_func);\n\t\t}\n");


		}else if(function_attr_interface.flag == SYMBOL_ASYNC)
		{

			formattedWrite(strings, "\tvoid %s_interface(%s, rpc_%s_callback rpc_callback, string bind_func = __FUNCTION__){\n\n", 
							function_attr_interface.func_name, func_args_strirngs.data, function_attr_interface.func_name);
			
			formattedWrite(strings, "\t\tauto req = new rpc_request;\n\n");
			
			formattedWrite(strings, "\t\treq.push(%s);\n\n", replaceAll(func_args_struct_strirngs.data, regex(`\,\s*\,`), ", "));

			formattedWrite(strings, "\t\trp_impl.async_call(req, delegate(rpc_response resp){\n\n");
			formattedWrite(strings, "\t\t\tif(resp.get_status == RESPONSE_STATUS.RS_OK){\n\n");
			formattedWrite(strings, "\t\t\t\t%s %s;\n\n", function_attr_interface.ret_value.get_type_name, function_attr_interface.ret_value.get_var_name);
			formattedWrite(strings, "\t\t\t\tresp.pop(%s);\n\n", function_attr_interface.ret_value.get_var_name);
			formattedWrite(strings, "\t\t\t\trpc_callback(%s);\n", function_attr_interface.ret_value.get_var_name);
			formattedWrite(strings, "\t\t\t}else{\n\t\t\t\tthrow new Exception(\"rpc sync call error, function:\" ~ bind_func);\n\t\t\t}}, bind_func);\n");

		}else
		{
			throw new Exception("function call method is failed, method:" ~ function_attr_interface.flag);
		}

		formattedWrite(strings, "\t}\n\n\n\n");
		
		return strings.data;
	}
}


class idl_inerface_dlang_code
{
	static string create_server_code_for_interface(idl_parse_interface idl_interface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "abstract class rpc_%s_interface{ \n\n", idl_interface.interface_name);
		formattedWrite(strings, "\tthis(rpc_server rp_server){ \n");
		formattedWrite(strings, "\t\trp_impl = new rpc_server_impl!(rpc_%s_service)(rp_server); \n", idl_interface.interface_name);
		
		foreach(k,v; idl_interface.function_list)
		{
			formattedWrite(strings, "\t\trp_impl.bind_request_callback(\"%s\", &this.%s_interface); \n\n", v.get_func_name, v.get_func_name);
		}
		
		formattedWrite(strings, "\t}\n\n");

		foreach(k,v; idl_interface.function_list)
		{
			formattedWrite(strings, idl_function_attr_code.create_server_interface_code(v, idl_interface.interface_name));
		}
		
		formattedWrite(strings, "\trpc_server_impl!(rpc_%s_service) rp_impl;\n}\n\n\n", idl_interface.interface_name);
		
		return strings.data;
	}


	static string create_server_code_for_service(idl_parse_interface idl_interface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "class rpc_%s_service: rpc_%s_interface{\n\n", idl_interface.interface_name, idl_interface.interface_name);
		formattedWrite(strings, "\tthis(rpc_server rp_server){\n");
		formattedWrite(strings, "\t\tsuper(rp_server);\n");
		formattedWrite(strings, "\t}\n\n");
		
		
		foreach(k,v; idl_interface.function_list)
		{
			formattedWrite(strings, idl_function_attr_code.create_server_service_code(v));
		}
		
		formattedWrite(strings,"}\n\n\n\n");

		return strings.data;
	}


	static string create_client_code_for_interface(idl_parse_interface idl_interface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "abstract class rpc_%s_interface{ \n\n", idl_interface.interface_name);
		formattedWrite(strings, "\tthis(rpc_client rp_client){ \n");
		formattedWrite(strings, "\t\trp_impl = new rpc_client_impl!(rpc_%s_service)(rp_client); \n", idl_interface.interface_name);
		formattedWrite(strings, "\t}\n\n");
		
		
		foreach(k,v; idl_interface.function_list)
		{
			if(v.flag == SYMBOL_ASYNC)
			{
				formattedWrite(strings, "\talias rpc_%s_callback = void delegate(%s);\n\n", v.func_name, v.ret_value.get_type_name);
			}
		
			formattedWrite(strings, idl_function_attr_code.create_client_interface_code(v, idl_interface.interface_name));
		}
		
		formattedWrite(strings, "\trpc_client_impl!(rpc_%s_service) rp_impl;\n}\n\n\n", idl_interface.interface_name);
		
		return strings.data;
	}


	static string create_client_code_for_service(idl_parse_interface idl_interface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "class rpc_%s_service: rpc_%s_interface{\n\n", idl_interface.interface_name, idl_interface.interface_name);
		formattedWrite(strings, "\tthis(rpc_client rp_client){\n");
		formattedWrite(strings, "\t\tsuper(rp_client);\n");
		formattedWrite(strings, "\t}\n\n");
		
		
		foreach(k,v; idl_interface.function_list)
		{
			formattedWrite(strings, idl_function_attr_code.create_client_service_code(v));
		}
		
		formattedWrite(strings, "}\n\n\n\n");

		return strings.data;
	}

}


