module IDL.IdlFlatbufferCreateCode;

import IDL.IdlParseStruct;
import IDL.IdlUnit;

import std.array : appender;
import std.format;


static string [string]idlFlatbufferVariable;

class IdlFlatbufferCode
{

	static string createFlatbufferCode(IdlParseStruct structInterface)
	{
		idlFlatbufferVariable["bool"] = "bool";
		idlFlatbufferVariable["byte"] = "byte";
		idlFlatbufferVariable["ubyte"] = "ubyte";
		idlFlatbufferVariable["short"] = "short";
		idlFlatbufferVariable["ushort"] = "ushort";
		idlFlatbufferVariable["int"] = "int";
		idlFlatbufferVariable["uint"] = "uint";
		idlFlatbufferVariable["long"] = "long";
		idlFlatbufferVariable["ulong"] = "ulong";
		idlFlatbufferVariable["float"] = "float";
		idlFlatbufferVariable["double"] = "double";
		idlFlatbufferVariable["char"] = "byte";
		idlFlatbufferVariable["string"] = "string";

		auto strings = appender!string();

		formattedWrite(strings, "table %sFB{\n", structInterface.structName);

		for(int i =1; i <= structInterface.memberAttrInfo.length; ++i)
		{
			auto v = structInterface.memberAttrInfo[i];

			auto typeName = idlFlatbufferVariable.get(v.getTypeName, null);

			if(typeName is null)
			{
				auto structName = idlStructList.get(v.getTypeName, null);

				if(structName !is null)
				{
					typeName = (structName.getName()~"FB");
				}
			}


			if(typeName !is null)
			{
				if(v.isArray)
				{
					formattedWrite(strings, "\t%s:[%s];\n", v.memberName, typeName);
					
				}else
				{
					formattedWrite(strings, "\t%s:%s;\n", v.memberName, typeName);
				}
			}else
			{
				throw new Exception("create flatbuffer file is faild, message name: "~ structInterface.structName ~ ", type:"~ v.typeName~" is not exits!");
			}
		}
		
		formattedWrite(strings, "}\n\n\n");
		
		return strings.data;

	}
}