module IDL.idl_struct_create_code;

import IDL.idl_parse_struct;
import IDL.idl_unit;

import std.array : appender;
import std.format;

class idl_struct_dlang_code
{
	static string create_server_code(idl_parse_struct idl_struct_interface)
	{
		auto strings = appender!string();
		formattedWrite(strings, "struct %s{\n", idl_struct_interface.struct_name);

		foreach(k, v; idl_struct_interface.member_attr_info)
		{
			formattedWrite(strings,"\t%s %s;\n", v.type_name, v.member_name);
		}

		formattedWrite(strings, "}\n\n\n");


		return strings.data;
	}
}
