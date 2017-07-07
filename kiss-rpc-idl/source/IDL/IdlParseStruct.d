module IDL.IdlParseStruct;

import std.array;
import std.regex;
import std.conv;
import std.stdio;

import IDL.IdlBaseInterface;
import IDL.IdlUnit;
import IDL.IdlSymbol;
import IDL.IdlStructCreateCode;

class MemberAttr{

	this(string type, string member)
	{
		typeName = type;
		memberName = member;
			
		writefln("message member: %s: %s", memberName, typeName);
	}

public:
	string typeName;
	string memberName;
}


class IdlParseStruct: IdlBaseInterface
{
	bool parse(string name, string structBodys)
	{
		this.structName = name;
		
		auto  MemberAttrList  = split(structBodys, ";");
		
		if(MemberAttrList.length < 1)
		{
			throw new Exception("parse meesgae member attr is failed, " ~ structBodys);
		}

		writeln("----------------------------");
		writefln("message name:%s", name);

		foreach(attr; MemberAttrList)
		{
			auto member = split(attr, ":");

			if(member.length > 1)
			{
				int index = to!(int)(member[1]);
				
				auto memberFlag = split(member[0], " ");
				
				if(memberFlag.length < 2)
				{
					throw new Exception("parse message member flag is failed, " ~ member[0]);
				}

				memberAttrInfo[index] = new MemberAttr(memberFlag[0], memberFlag[1]);
			}
		}

		writeln("----------------------------\n\n");

		return true;
	}


	string getName()
	{
		return this.structName;
	}


	string createCodeForLanguage(CODE_LANGUAGE language)
	{
		string codeText;
		
		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG: codeText = IdlStructDlangCode.createServerCode(this); break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
				
			default:
				throw new Exception("language is not exits!!");
		}

		return codeText;
	}


	string createServerCodeForInterface(CODE_LANGUAGE language)
	{
		return "";
	}

	string createServerCodeForService(CODE_LANGUAGE language)
	{
		return "";
	}
	
	string createClientCodeForService(CODE_LANGUAGE language)
	{
		return "";
	}

	string createClientCodeForInterface(CODE_LANGUAGE language)
	{
		return "";
	}

public:
	string structName;
	MemberAttr[int] memberAttrInfo;
}

