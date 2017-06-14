module IDL.idl_parse_interface;

import std.array;
import std.regex;
import std.conv;
import std.stdio;
import std.array : appender;
import std.format;

import IDL.idl_base_interface;
import IDL.idl_unit;


class function_arg
{
	this(string type, string var)
	{
		type_name = type;
		var_name = var;

		writefln("function argument: %s:%s", var_name, type_name);
	}

	string get_var_name()
	{
		return var_name;
	}

	string get_type_name()
	{
		return type_name;
	}

	string create_server_code()
	{
		auto strings = appender!string();

		auto dlang_var_name = idl_dlang_variable.get(type_name, null);

		if(dlang_var_name != null)
		{
			formattedWrite(strings, "\t\t %s %s;\n", type_name, var_name);

		}else
		{

		}

		return strings.data;
	}


private:
	string type_name;
	string var_name;
}

class function_attr
{
	this(string flag_attr, string func_tlp)
	{
		this.flag = flag_attr;

		auto format_func_tlp = replaceAll(func_tlp, regex(`\(|\)`), " ");

		format_func_tlp = replaceAll(format_func_tlp, regex(`\,`),"");
		format_func_tlp = replaceAll(format_func_tlp, regex(`^\s*`), "");
		format_func_tlp = replaceAll(format_func_tlp, regex(`\s*$`), "");

		auto func_tlp_list = split(format_func_tlp, " ");

		if(func_tlp_list.length < 4 && func_tlp_list.length % 2 == 0)
		{
			throw new Exception("parse funtion arguments is failed, " ~ func_tlp);
		}

		ret_type = func_tlp_list[0];
		func_name = func_tlp_list[1];

		int func_arg_index = 0;
		writeln("********************************");
		writefln("function name:%s, return value:%s", func_name, ret_type);

		for(int i = 2; i<func_tlp_list.length; i+=2)
		{
			func_arg_map[func_arg_index++] = new function_arg(func_tlp_list[i], func_tlp_list[i+1]);
		}

		writeln("********************************\n");
	}

	string get_func_name()
	{
		return this.func_name;
	}

	string create_server_interface_code(string inerface_name)
	{
		auto strings = appender!string();
		formattedWrite(strings, "\t void %s_interface(rpc_request req){\n\n", func_name);

		if(ret_type != "void")
		{
			formattedWrite(strings, "\t\t auto resp = new rpc_response(req);\n\n");
		}

		foreach(k,v ;func_arg_map)
		{
			formattedWrite(strings, v.create_server_code);
		}

		formattedWrite(strings, "\n\n");

		auto func_args_strirngs = appender!string();

		for(int i = 0; i<func_arg_map.length; ++ i)
		{
			auto v = func_arg_map[i];

			if(i == func_arg_map.length -1)
				formattedWrite(func_args_strirngs, "%s", v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s, ", v.get_var_name);
		}

		formattedWrite(strings, "\t\treq.pop(%s);\n", func_args_strirngs.data);

		if(ret_type == "void")
		{
			formattedWrite(strings, "\t\t(cast(rpc_%s_service)this).%s(%s);\n", inerface_name, func_name, func_args_strirngs.data);
		
		}else
		{
			formattedWrite(strings, "\t\tresp.push((cast(rpc_%s_service)this).%s(%s));\n", inerface_name, func_name, func_args_strirngs.data);
			formattedWrite(strings, "\t\trp_impl.response(resp);\n");
		}

		formattedWrite(strings, "\t}\n\n");

		return strings.data;
	}

	string create_server_service_code()
	{
		auto strings = appender!string();

		auto func_args_strirngs = appender!string();
		
		for(int i = 0; i<func_arg_map.length; i++)
		{
			auto v = func_arg_map[i];

			if(i == func_arg_map.length -1 )
				formattedWrite(func_args_strirngs, "%s %s", v.get_type_name, v.get_var_name);
			else
				formattedWrite(func_args_strirngs, "%s %s, ", v.get_type_name, v.get_var_name);
		}

		formattedWrite(strings,"\t%s %s(%s)", ret_type, func_name, func_args_strirngs.data);

		if(ret_type == "void")
		{
			formattedWrite(strings,"{\n\n\n\t}\n\n");

		}else
		{
			formattedWrite(strings,"{\n\n\n\t\treturn %s\n\t}\n\n", ret_type);
		}

		return strings.data;
	}



private:
	string flag;
	string ret_type;
	string func_name;

	function_arg[int] func_arg_map;
}

class idl_parse_interface : idl_base_interface
{
	bool parse(string name, string struct_bodys)
	{
		this.interface_name = name;

		auto  member_attr_list  = split(struct_bodys, ";");

		if(member_attr_list.length < 1)
		{
			throw new Exception("parse service member attr is failed, " ~ struct_bodys);
		}

		writeln("----------------------------");
		writefln("serivce name:%s", name);

		foreach(attr; member_attr_list)
		{
			auto member = split(attr, ":");
			
			if(member.length > 1)
			{
				string 	flag = member[0];
				string func_tlp = member[1];

				function_list[func_index++] = new function_attr(member[0], member[1]);
			}
		}

		writeln("----------------------------\n\n");
	
		return true;
	}

	string get_name()
	{
		return this.interface_name;
	}

	string create_server_code()
	{
		auto strings = appender!string();

		formattedWrite(strings, "abstract class rpc_%s_interface{ \n\n", interface_name);
		formattedWrite(strings, "\t this(rpc_server rp_server){ \n");
		formattedWrite(strings, "\t\t rp_impl = new rpc_server_impl!(%s_srevice)(rp_server); \n", interface_name);

		foreach(k,v; function_list)
		{
			formattedWrite(strings, "\t\t rp_impl.bind_request_callback(\"%s\", &this.%s_interface); \n\n", v.get_func_name, v.get_func_name);
		}

		formattedWrite(strings, "\t }\n\n");


		foreach(k,v; function_list)
		{
			formattedWrite(strings, v.create_server_interface_code(interface_name));
		}

		formattedWrite(strings, "\trpc_server_impl!(rpc_%s_service) rp_impl;\n}\n\n\n", interface_name);

		formattedWrite(strings, "class rpc_%s_service : rpc_%s_interface{\n\n", interface_name, interface_name);
		formattedWrite(strings, "\tthis(rpc_server rp_server){\n");
		formattedWrite(strings, "\t\tsuper(rp_server);\n");
		formattedWrite(strings,"\t}\n\n");


		foreach(k,v; function_list)
		{
			formattedWrite(strings, v.create_server_service_code());
		}

		formattedWrite(strings,"}");

		return strings.data;
	}



private:
	int func_index;
	string interface_name;
	function_attr[int] function_list;
}