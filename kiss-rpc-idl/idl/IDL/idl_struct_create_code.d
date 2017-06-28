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
		formattedWrite(strings, "struct %s{\n\n", idl_struct_interface.struct_name);

		foreach(k, v; idl_struct_interface.member_attr_info)
		{
			formattedWrite(strings, "\t%s %s;\n", v.type_name, v.member_name);
		}

		auto member_list_str = appender!string();

		foreach(k,v; idl_struct_interface.member_attr_info)
		{
			formattedWrite(member_list_str, "%s, ", v.type_name);
		}

		formattedWrite(strings, "\n\tTypeTuple!(%s) member_list;\n\n", member_list_str.data);

		formattedWrite(strings, "\tvoid create_type_tulple(){\n\n");

		int index = 0;

		foreach(k, v; idl_struct_interface.member_attr_info)
		{
			formattedWrite(strings, "\t\tmember_list[%s] = %s;\n", index++, v.member_name);
		}

		formattedWrite(strings, "\t}\n\n");

		formattedWrite(strings, "\tvoid restore_type_tunlp(){\n\n");
		index = 0;

		foreach(k, v; idl_struct_interface.member_attr_info)
		{
			formattedWrite(strings, "\t\t%s = member_list[%s];\n", v.member_name, index++);
		}

		formattedWrite(strings, "\t}\n\n");

		formattedWrite(strings, "}\n\n\n");

		return strings.data;
	}
}
