module IDL.IdlStructCreateCode;

import IDL.IdlParseStruct;
import IDL.IdlUnit;

import std.array : appender;
import std.format;
import std.algorithm.iteration : map;
import std.numeric : entropy;
import std.algorithm.sorting;

class IdlStructDlangCode
{
	static string createServerCode(IdlParseStruct idlStructInterface)
	{
		auto strings = appender!string();
		formattedWrite(strings, "struct %s{\n\n", idlStructInterface.structName);


		for(int i =1; i <= idlStructInterface.memberAttrInfo.length; ++i)
		{
			auto v = idlStructInterface.memberAttrInfo[i];
			formattedWrite(strings, "\t%s %s;\n", v.typeName, v.memberName);
		}

		auto memberList_str = appender!string();

		for(int i =1; i <= idlStructInterface.memberAttrInfo.length; ++i)
		{
			auto v = idlStructInterface.memberAttrInfo[i];
			formattedWrite(memberList_str, "%s, ", v.typeName);
		}

		formattedWrite(strings, "\n\tTypeTuple!(%s) memberList;\n\n", memberList_str.data);

		formattedWrite(strings, "\tvoid createTypeTulple(){\n\n");

		int index = 0;

		for(int i =1; i <= idlStructInterface.memberAttrInfo.length; ++i)
		{
			auto v = idlStructInterface.memberAttrInfo[i];
			formattedWrite(strings, "\t\tmemberList[%s] = %s;\n", index++, v.memberName);
		}

		formattedWrite(strings, "\t}\n\n");

		formattedWrite(strings, "\tvoid restoreTypeTunlp(){\n\n");
		index = 0;

		for(int i =1; i <= idlStructInterface.memberAttrInfo.length; ++i)
		{
			auto v = idlStructInterface.memberAttrInfo[i];
			formattedWrite(strings, "\t\t%s = memberList[%s];\n", v.memberName, index++);
		}

		formattedWrite(strings, "\t}\n\n");

		formattedWrite(strings, "}\n\n\n");

		return strings.data;
	}
}
