module IDL.IdlStructCreateCode;

import IDL.IdlParseStruct;
import IDL.IdlUnit;

import std.array : appender;
import std.format;

class IdlStructDlangCode
{
	static string createServerCode(IdlParseStruct idlStructInterface)
	{
		auto strings = appender!string();
		formattedWrite(strings, "struct %s{\n\n", idlStructInterface.structName);

		foreach(k, v; idlStructInterface.memberAttrInfo)
		{
			formattedWrite(strings, "\t%s %s;\n", v.typeName, v.memberName);
		}

		auto memberList_str = appender!string();

		foreach(k,v; idlStructInterface.memberAttrInfo)
		{
			formattedWrite(memberList_str, "%s, ", v.typeName);
		}

		formattedWrite(strings, "\n\tTypeTuple!(%s) memberList;\n\n", memberList_str.data);

		formattedWrite(strings, "\tvoid createTypeTulple(){\n\n");

		int index = 0;

		foreach(k, v; idlStructInterface.memberAttrInfo)
		{
			formattedWrite(strings, "\t\tmemberList[%s] = %s;\n", index++, v.memberName);
		}

		formattedWrite(strings, "\t}\n\n");

		formattedWrite(strings, "\tvoid restoreTypeTunlp(){\n\n");
		index = 0;

		foreach(k, v; idlStructInterface.memberAttrInfo)
		{
			formattedWrite(strings, "\t\t%s = memberList[%s];\n", v.memberName, index++);
		}

		formattedWrite(strings, "\t}\n\n");

		formattedWrite(strings, "}\n\n\n");

		return strings.data;
	}
}
