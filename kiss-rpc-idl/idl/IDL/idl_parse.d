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
		idl_dlang_variable["void"] = "void";
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

					idl_base_interface idl_inerface;

					switch(symbol_attr[0])
					{
						case SYMBOL_STRUCT:
							idl_inerface  = new idl_parse_struct;
							break;

						case SYMBOL_INTERFACE:
							idl_inerface = new idl_parse_interface;
							break;	

						default:
							throw new Exception("parse symbol attr is error,  symbol: " ~ symbol_attr[0]);
					}
					
					if(idl_inerface.parse(symbol_attr[1], symbol_flag[1]))
					{
						switch(symbol_attr[0])
						{
							case SYMBOL_STRUCT:
								idl_struct_list[idl_inerface.get_name] = idl_inerface;
								break;

							case SYMBOL_INTERFACE:
								idl_inerface_list[idl_inerface.get_name] = idl_inerface;
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
			writefln("##############%s", k);
			writeln(v.create_server_code());
		}
	}

private:
	idl_base_interface[string] idl_inerface_list;
}

