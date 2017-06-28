module IDL.idl_parse;

import std.array;
import std.range.primitives : popFrontN;
import std.array : appender;
import std.regex;
import std.stdio;
import std.conv;
import std.file;
import std.format;

import IDL.idl_symbol;
import IDL.idl_parse_struct;
import IDL.idl_parse_interface;
import IDL.idl_base_interface;
import IDL.idl_unit;


class idl_parse
{
	this()
	{
		//idl_dlang_variable["void"] = "void";
		idl_dlang_variable["bool"] = "bool";
		idl_dlang_variable["byte"] = "byte";
		idl_dlang_variable["ubyte"] = "ubyte";
		idl_dlang_variable["short"] = "short";
		idl_dlang_variable["int"] = "int";
		idl_dlang_variable["uint"] = "uint";
		idl_dlang_variable["long"] = "long";
		idl_dlang_variable["ulong"] = "ulong";
		idl_dlang_variable["float"] = "float";
		idl_dlang_variable["double"] = "double";
		idl_dlang_variable["char"] = "char";
		idl_dlang_variable["wchar"] = "dchar";
		idl_dlang_variable["dchar"] = "dchar";
		idl_dlang_variable["string"] = "string";
	}

	void set_parse_file(string path)
	{
		in_file_path = path;
	}

	void set_output_file(string path)
	{
		out_file_path = path;
	}

	void set_file_name(string name)
	{
		file_name = name;
	}

	void start_parse()
	{
		auto file = File(in_file_path);
	
		string text;

		while(!file.eof)
		{
			text ~= file.readln();
		}

		this.parse(text);
	}

	bool parse(string data)
	{
		data = replaceAll(data, regex(`\/\/[^\n]*`), "");
		data = replaceAll(data, regex("\n|\t"), "");
		data = replaceAll(data, regex(`\s{2,}`), "");

		auto clesses = split(data, regex(`[@\}]`));

		if(clesses.length == 0)
		{
			throw new Exception("parse classes is failed, no class struct!!", data);
		}

		foreach(c; clesses)
		{
				auto symbol_flag = split(c, "{");
				
				if(symbol_flag.length == 2)
				{
					
					auto symbol_attr = split(symbol_flag[0], ":");
					
					if(symbol_attr.length != 2)
					{
						throw new Exception("parse symbol  attr is failed,  symbol missing :, " ~ symbol_flag[0]);
					}

					idl_base_interface idl_interface;

					switch(symbol_attr[0])
					{
						case SYMBOL_STRUCT:
							idl_interface  = new idl_parse_struct;
							break;

						case SYMBOL_INTERFACE:
							idl_interface = new idl_parse_interface;
							break;	

						default:
							throw new Exception("parse symbol attr is error,  symbol: " ~ symbol_attr[0]);
					}
					
					if(idl_interface.parse(symbol_attr[1], symbol_flag[1]))
					{
						switch(symbol_attr[0])
						{
							case SYMBOL_STRUCT:
								idl_struct_list[idl_interface.get_name] = cast(idl_parse_struct)idl_interface;
								break;

							case SYMBOL_INTERFACE:
								idl_inerface_list[idl_interface.get_name] = idl_interface;
								break;

							default:
								throw new Exception("parse symbol attr is error,  symbol: " ~ symbol_attr[0]);
						}
					}
			}
		}

		this.create_code();
		return true;
	}


	void create_code()
	{
		string server_code_interface, server_code_service;
		string client_code_interface, client_code_service;
		string struct_code;

		auto server_interface_strings = appender!string();
		formattedWrite(server_interface_strings, "module KissRpc.IDL.%s_interface;\n\n", file_name);
		formattedWrite(server_interface_strings, "import KissRpc.IDL.%s_message;\n", file_name);
		formattedWrite(server_interface_strings, "import KissRpc.IDL.%s_service;\n\n", file_name);

		formattedWrite(server_interface_strings, "import KissRpc.rpc_server;\n");
		formattedWrite(server_interface_strings, "import KissRpc.rpc_server_impl;\n");
		formattedWrite(server_interface_strings, "import KissRpc.rpc_response;\n");
		formattedWrite(server_interface_strings, "import KissRpc.rpc_request;\n");

		auto server_service_strings = appender!string();
		formattedWrite(server_service_strings, "module KissRpc.IDL.%s_service;\n\n", file_name);
		formattedWrite(server_service_strings, "import KissRpc.IDL.%s_interface;\n", file_name);
		formattedWrite(server_service_strings, "import KissRpc.IDL.%s_message;\n\n", file_name);
		formattedWrite(server_service_strings, "import KissRpc.rpc_server;\n\n");


		auto client_interface_strings = appender!string();
		formattedWrite(client_interface_strings, "module KissRpc.IDL.%s_interface;\n\n", file_name);
		formattedWrite(client_interface_strings, "import KissRpc.IDL.%s_message;\n", file_name);
		formattedWrite(client_interface_strings, "import KissRpc.IDL.%s_service;\n\n", file_name);

		formattedWrite(client_interface_strings, "import KissRpc.rpc_request;\n");
		formattedWrite(client_interface_strings, "import KissRpc.rpc_client_impl;\n");
		formattedWrite(client_interface_strings, "import KissRpc.rpc_client;\n");
		formattedWrite(client_interface_strings, "import KissRpc.rpc_response;\n\n");


		auto client_service_strings = appender!string();
		formattedWrite(client_service_strings, "module KissRpc.IDL.%s_service;\n\n\n", file_name);
		formattedWrite(client_service_strings, "import KissRpc.IDL.%s_interface;\n", file_name);
		formattedWrite(client_service_strings, "import KissRpc.IDL.%s_message;\n\n", file_name);
		formattedWrite(client_service_strings, "import KissRpc.rpc_client;\n\n");



		auto struct_strings = appender!string();
		formattedWrite(struct_strings, "module KissRpc.IDL.%s_message;\n", file_name);
		formattedWrite(struct_strings, "import std.typetuple;\n\n\n");


		foreach(k, v; idl_inerface_list)
		{
			server_code_interface ~= v.create_server_code_for_interface(CODE_LANGUAGE.CL_DLANG);
			server_code_service ~= v.create_server_code_for_service(CODE_LANGUAGE.CL_DLANG);

			client_code_interface ~= v.create_client_code_for_interface(CODE_LANGUAGE.CL_DLANG);
			client_code_service ~= v.create_client_code_for_service(CODE_LANGUAGE.CL_DLANG);
		}

		foreach(k, v; idl_struct_list)
		{
			struct_code ~= v.create_code_for_language(CODE_LANGUAGE.CL_DLANG);
		}

		if(!exists(out_file_path ~ "/server/"))
				mkdir(out_file_path ~ "/server/");

		auto file = File(out_file_path ~ "/server/" ~ file_name ~ "_interface.d", "w+");
		file.write(server_interface_strings.data ~ server_code_interface);

		file = File(out_file_path ~ "/server/" ~ file_name ~ "_service.d", "w+");
		file.write(server_service_strings.data ~ server_code_service);

		file = File(out_file_path ~ "/server/" ~ file_name ~ "_message.d", "w+");
		file.write(struct_strings.data ~ struct_code);

		if(!exists(out_file_path ~ "/client/"))
				mkdir(out_file_path ~ "/client/");

		file = File(out_file_path ~ "/client/" ~ file_name ~ "_interface.d", "w+");
		file.write(client_interface_strings.data ~ client_code_interface);

		file = File(out_file_path ~ "/client/" ~ file_name ~ "_service.d", "w+");
		file.write(client_service_strings.data ~ client_code_service);

		file = File(out_file_path ~ "/client/" ~ file_name ~ "_message.d", "w+");
		file.write(struct_strings.data ~ struct_code);
	}

private:
	idl_base_interface[string] idl_inerface_list;

	string in_file_path = ".";
	string out_file_path = ".";
	string file_name;
}

