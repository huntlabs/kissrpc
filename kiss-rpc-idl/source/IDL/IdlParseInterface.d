module IDL.IdlParseInterface;

import std.array;
import std.regex;
import std.conv;
import std.stdio;
import std.array : appender;
import std.format;

import IDL.IdlBaseInterface;
import IDL.IdlUnit;
import IDL.IdlInerfaceCreateCode;
import IDL.IdlParseStruct;

class FunctionArg
{
	this(string type, string var)
	{
		typeName = type;
		varName = var;

		if(idlDlangVariable.get(typeName, null) is null && idlStructList.get(typeName, null) is null)
		{
			throw new Exception("parse type error, is not exist, type:" ~ typeName);
		}

		writefln("function argument: %s:%s", varName, typeName);
	}

	string getVarName()
	{
		return varName;
	}

	string getTypeName()
	{
		return typeName;
	}

public:
	string typeName;
	string varName;
}

class FunctionAttr
{
	this(string funcTlp)
	{
		auto formatFuncTlp = replaceAll(funcTlp, regex(`\(|\)`), " ");

		formatFuncTlp = replaceAll(formatFuncTlp, regex(`\,`),"");
		formatFuncTlp = replaceAll(formatFuncTlp, regex(`^\s*`), "");
		formatFuncTlp = replaceAll(formatFuncTlp, regex(`\s*$`), "");

		auto funcTlpList = split(formatFuncTlp, " ");

		if(funcTlpList.length < 4 && funcTlpList.length % 2 == 0)
		{
			throw new Exception("parse function arguments is failed, " ~ funcTlp);
		}

		writeln("********************************");

		retValue = new FunctionArg(funcTlpList[0], "ret_" ~ funcTlpList[0]);

		funcName = funcTlpList[1];

		int funcArgIndex = 0;
		writefln("function name:%s, return value:%s", funcName, retValue.getTypeName);

		for(int i = 2; i<funcTlpList.length; i+=2)
		{
			funcArgMap[funcArgIndex++] = new FunctionArg(funcTlpList[i], funcTlpList[i+1]);
		}

		writeln("********************************\n");
	}

	string getFuncName()
	{
		return this.funcName;
	}


public:
	FunctionArg retValue;
	string funcName;
	FunctionArg[int] funcArgMap;
}

class IdlParseInterface : IdlBaseInterface
{
	bool parse(string name, string structBodys)
	{
		this.interfaceName = name;

		auto  MemberAttrList  = split(structBodys, ";");

		if(MemberAttrList.length < 1)
		{
			throw new Exception("parse service member attr is failed, " ~ structBodys);
		}

		writeln("----------------------------");
		writefln("serivce name:%s", name);

		foreach(attr; MemberAttrList)
		{
			if(attr.length > 1)
			{
				auto funcAttr = new FunctionAttr(attr);
				functionList[funcIndex++] = funcAttr;
			}
		}

		writeln("----------------------------\n\n");
		return true;
	}

	string getName()
	{
		return this.interfaceName;
	}


	string createServerCodeForInterface(CODE_LANGUAGE language)
	{
		string codeText;

		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG: codeText = idl_inerface_dlang_code.createServerCodeForInterface(this); break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
			
			default:
				throw new Exception("language is not exits!!");
		}

		return codeText;
	}

	string createServerCodeForService(CODE_LANGUAGE language)
	{
		string codeText;
		
		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG: codeText = idl_inerface_dlang_code.createServerCodeForService(this); break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
				
			default:
				throw new Exception("language is not exits!!");
		}
		
		return codeText;
	}


	string createClientCodeForInterface(CODE_LANGUAGE language)
	{
		string codeText;
		
		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG:codeText = idl_inerface_dlang_code.createClientCodeForInterface(this); break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
				
			default:
				throw new Exception("language is not exits!!");
		}
		
		return codeText;
	}

	string createClientCodeForService(CODE_LANGUAGE language)
	{
		string codeText;
		
		switch(language)
		{
			case CODE_LANGUAGE.CL_CPP:break;
			case CODE_LANGUAGE.CL_DLANG:codeText = idl_inerface_dlang_code.createClientCodeForService(this); break;
			case CODE_LANGUAGE.CL_GOLANG:break;
			case CODE_LANGUAGE.CL_JAVA:break;
				
			default:
				throw new Exception("language is not exits!!");
		}
		
		return codeText;
	}


public:
	int funcIndex;
	string interfaceName;
	FunctionAttr[int] functionList;
}