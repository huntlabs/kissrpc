module IDL.idl_parse_struct;

import std.array;
import std.regex;
import std.conv;
import std.stdio;

import IDL.idl_base_interface;
import IDL.idl_unit;
import IDL.idl_symbol;

class member_attr{

	this(string type, string member)
	{
		type_name = type;
		member_name = member;

		writefln("message member: %s: %s", member_name, type_name);
	}

public:
	string type_name;
	string member_name;
}


class idl_parse_struct : idl_base_interface
{
	bool parse(string name, string struct_bodys)
	{
		this.struct_name = name;
		
		auto  member_attr_list  = split(struct_bodys, ";");
		
		if(member_attr_list.length < 1)
		{
			throw new Exception("parse meesgae member attr is failed, " ~ struct_bodys);
		}

		writeln("----------------------------");
		writefln("message name:%s", name);

		foreach(attr; member_attr_list)
		{
			auto member = split(attr, ":");

			if(member.length > 1)
			{
				int index = to!(int)(member[1]);
				
				auto member_flag = split(member[0], " ");
				
				if(member_flag.length < 2)
				{
					throw new Exception("parse message member flag is failed, " ~ member[0]);
				}

				member_attr_info[index] = new member_attr(member_flag[0], member_flag[1]);
			}
		}

		writeln("----------------------------\n\n");

		return true;
	}


	string get_name()
	{
		return this.struct_name;
	}


	string create_server_code_for_language(CODE_LANGUAGE language)
	{
		string code_text;
		
		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG:break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
				
			default:
				new Exception("language is not exits!!");
		}

		return code_text;
	}

	string create_client_code_for_language(CODE_LANGUAGE language)
	{
		string code_text;
		
		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG:break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
				
			default:
				new Exception("language is not exits!!");
		}
		
		return code_text;
	}

public:
	string struct_name;
	member_attr[int] member_attr_info;
}

