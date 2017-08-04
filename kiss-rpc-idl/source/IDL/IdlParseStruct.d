module IDL.IdlParseStruct;

import std.array;
import std.regex;
import std.conv;
import std.stdio;
import std.array : appender;
import std.format;
import std.uni;

import IDL.IdlBaseInterface;
import IDL.IdlUnit;
import IDL.IdlSymbol;
import IDL.IdlStructCreateCode;
import IDL.IdlParseInterface;

class MemberAttr{

	this(string type, string member)
	{
	
		auto type_split = split(type,"[]");

		if(type_split.length > 1)
		{
			typeName = type_split[0];
			isArray = true;
		}else
		{
			typeName = type;
			isArray = false;
		}

		if(typeName == "string")
		{
			isString = true;
		}else
		{
			isString = false;
		}

		if(idlStructList.get(typeName, null) !is null)
		{
			isClass = true;
		}else
		{
			if(idlDlangVariable.get(typeName, null) is null)
			{
				throw new Exception("Idl Incorrect type, type name:" ~ typeName);
			}

			isClass = false;
		}

		memberName = member;
	
		writefln("message member: %s: %s", memberName, type);

	}

	string getTypeName()
	{
		return typeName;
	}

	string getVarName()
	{
		return memberName;
	}


public:
	string typeName;
	string memberName;
	bool isArray;
	bool isString;
	bool isClass;
}


class IdlParseStruct: IdlBaseInterface
{
	bool parse(string filePath, string name, string structBodys)
	{
		if(name[0].isUpper == false)
		{
			throw new Exception("parse meesgae name is failed, The first character of the name is capitalized, message name:" ~ name);
		}


		this.structName = name;
		
		auto  MemberAttrList  = split(structBodys, ";");
		
		if(MemberAttrList.length < 1)
		{
			throw new Exception("parse meesgae member attr is failed, " ~ structBodys);
		}

		writeln("----------------------------");
		writefln("message name:%s ", name);

		foreach(attr; MemberAttrList)
		{
			if(attr.empty == false)
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
				}else
				{
					throw new Exception("parse message name:" ~ name ~ ", member:" ~ attr ~", please set the number!!!");
				}
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

	static uint DeserializeRecursive = -1;
	static string createDeserializeCodeForFlatbuffer(IdlParseStruct structInfo, string varName, string fbName)
	{
		auto strings = appender!string();

		auto memberAttrInfo = structInfo.memberAttrInfo;
		auto structName = structInfo.structName;
		DeserializeRecursive++;

		for(int i=1; i<=memberAttrInfo.length; i++)
		{
			string iterName =  memberAttrInfo[i].getVarName;
			string iterType = memberAttrInfo[i].getTypeName;

			foreach(j; 0..DeserializeRecursive) formattedWrite(strings, "\t");

			if(memberAttrInfo[i].isArray)
			{
				if(memberAttrInfo[i].isClass)
				{
					auto tmpName = stringToLower(iterType, 0)~"Tmp";

					formattedWrite(strings, "\t\tforeach(%s; %s.%s){\n\n", iterName, fbName, iterName);
					formattedWrite(strings, "\t\t\t%s %s;\n", iterType, tmpName);
					formattedWrite(strings, "%s", IdlParseStruct.createDeserializeCodeForFlatbuffer(idlStructList[iterType], tmpName, iterName));
					formattedWrite(strings, "\t\t\t%s.%s ~= %s;\n", varName, iterName, tmpName);
				}else
				{
					formattedWrite(strings, "\t\tforeach(%s; %s.%s){\n\n", iterName, fbName, iterName);
					formattedWrite(strings, "\t\t\t%s.%s ~= %s;\n", varName, iterName, iterName);
				}
				
				formattedWrite(strings, "\t\t}\n\n");

			}else if(memberAttrInfo[i].isClass)
			{
				formattedWrite(strings, "\t\t%s %s;\n", iterType, iterName);
				formattedWrite(strings, "%s", IdlParseStruct.createDeserializeCodeForFlatbuffer(idlStructList[iterType], iterName, iterName));
			}else
			{
				formattedWrite(strings, "\t\t%s.%s = %s.%s;\n", varName, iterName, fbName, iterName);
			}
		}

		DeserializeRecursive--;
		return strings.data;
	}



	static uint serializeRecursive = -1;
	static string createSerializeCodeForFlatbuffer(IdlParseStruct structInfo, string varName)
	{
		auto strings = appender!string();
		auto argsStrings = appender!string();

		auto memberAttrInfo = structInfo.memberAttrInfo;
		auto structName = structInfo.structName;

		serializeRecursive++;


		for(int i = 1; i <= memberAttrInfo.length; i++)
		{
			string iterName =  memberAttrInfo[i].getVarName;
			string iterType = memberAttrInfo[i].getTypeName;

			if(memberAttrInfo[i].isArray)
			{
				if(memberAttrInfo[i].isClass)
				{
					formattedWrite(strings, "uint[] %sPosArray;\n", iterName);
					formattedWrite(strings, "\t\tforeach(%s; %s.%s){\n\n", iterName, varName, iterName);

					formattedWrite(strings, "\t\t%s", IdlParseStruct.createSerializeCodeForFlatbuffer(idlStructList[iterType], iterName));

					formattedWrite(strings, "\t\t\t%sPosArray ~= %sPos;\n", iterName, iterName);
		
				}else if(memberAttrInfo[i].isString)
				{
					formattedWrite(strings, "uint[] %sPosArray;\n", iterName);
					formattedWrite(strings, "\t\tforeach(%s; %s.%s){\n\n", iterName, varName, iterName);

					formattedWrite(strings, "\t\t\tauto %sPos =  builder.createString(%s);\n", iterName, iterName);
					formattedWrite(strings, "\t\t\t%sPosArray ~= %sPos;\n", iterName, iterName);

				}else
				{
					formattedWrite(strings, "%s[] %sPosArray;\n", iterType, iterName);
					formattedWrite(strings, "\t\tforeach(%s; %s.%s){\n\n", iterName, varName, iterName);

					formattedWrite(strings, "\t\t\t%sPosArray ~= %s;\n", iterName, iterName);
				}

				formattedWrite(strings, "\t\t}\n\n");
				
				formattedWrite(argsStrings, "%sFB.create%sVector(builder, %sPosArray), ", structName, stringToUpper(iterName, 0), iterName);

				foreach(j; 0..serializeRecursive) formattedWrite(strings, "\t");


			}else if(memberAttrInfo[i].isClass)
			{
				formattedWrite(strings, "\t\tauto %s = %s.%s;\n", iterName, varName, iterName);
				formattedWrite(strings, IdlParseStruct.createSerializeCodeForFlatbuffer(idlStructList[iterType], iterName));
				formattedWrite(argsStrings, "%sPos, ", iterName);

			}else if(memberAttrInfo[i].isString)
			{
				formattedWrite(argsStrings, "builder.createString(%s.%s), ", varName, iterName);
			}
			else
			{
				formattedWrite(argsStrings, "%s.%s, ", varName, iterName);
			}
		}

		formattedWrite(strings, "\t\tauto %sPos = %sFB.create%sFB(builder, %s);\n", varName, structName, structName, argsStrings.data);

		serializeRecursive--;
		return strings.data;
	}



public:
	string structName;
	MemberAttr[int] memberAttrInfo;
}

