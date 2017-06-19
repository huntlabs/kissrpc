module IDL.idl_parse;

import std.array;
import std.range.primitives : popFrontN;
import std.regex;
import std.stdio;

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

	bool parse(string data)
	{
		data = replaceAll(data, regex(`\/\/[^\n]*`), "");
		data = replaceAll(data, regex("\n"), "");
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
		foreach(k, v ; idl_inerface_list)
		{
			auto server_code = v.create_server_code_for_language(CODE_LANGUAGE.CL_DLANG);
			auto client_code = v.create_client_code_for_language(CODE_LANGUAGE.CL_DLANG);

			auto file = File(k~"_server.d", "w+");
			file.write(server_code);

			file = File(k~"_client.d", "w+");
			file.write(client_code);
		}
	}

private:
	idl_base_interface[string] idl_inerface_list;
}

