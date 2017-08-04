module IDL.IdlStructCreateCode;

import IDL.IdlParseStruct;
import IDL.IdlUnit;

import std.array : appender;
import std.format;
import std.algorithm.iteration : map;
import std.numeric : entropy;
import std.algorithm.sorting;
import std.stdio;

class IdlStructDlangCode
{
	static string createServerCode(IdlParseStruct idlStructInterface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "struct %s{\n\n", idlStructInterface.structName);


		for(int i =1; i <= idlStructInterface.memberAttrInfo.length; i++)
		{
			
			auto v = idlStructInterface.memberAttrInfo[i];

			if(v.isArray)
			{
				formattedWrite(strings, "\t%s[] %s;\n", v.typeName, v.memberName);

			}else
			{
				formattedWrite(strings, "\t%s %s;\n", v.typeName, v.memberName);
			}
		}

		formattedWrite(strings, "}\n\n\n");

		return strings.data;
	}
}
