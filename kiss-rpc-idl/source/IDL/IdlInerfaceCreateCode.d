module IDL.IdlInerfaceCreateCode;

import std.array : appender;
import std.format;
import std.regex;
import std.stdio;

import IDL.IdlParseInterface;
import IDL.IdlStructCreateCode;
import IDL.IdlUnit;
import IDL.IdlSymbol;


class IdlFunctionArgCode
{
	static string createServerCode(FunctionArg functionInerface)
	{
		auto strings = appender!string();
		
		auto dlangVarName = idlDlangVariable.get(functionInerface.typeName, null);
		
		if(dlangVarName == null)
		{
			auto dlangStructName = idlStructList.get(functionInerface.typeName, null);

			if(dlangStructName is null)
			{
				throw new Exception("not parse symbol for struct name: " ~ functionInerface.typeName);
			}
		}

		formattedWrite(strings, "\t\t%s %s;\n", functionInerface.typeName, functionInerface.varName);

		return strings.data;
	}


	static string createClientCode(FunctionArg functionInerface)
	{
		auto strings = appender!string();
		
		auto dlangVarName = idlDlangVariable.get(functionInerface.typeName, null);
		
		if(dlangVarName == null)
		{
			auto dlangStructName = idlStructList.get(functionInerface.typeName, null);
			
			if(dlangStructName is null)
			{
				throw new Exception("not parse symbol for struct name: " ~ functionInerface.typeName);
			}
		}
		
		formattedWrite(strings, "\t\t %s %s;\n", functionInerface.typeName, functionInerface.varName);
		
		return strings.data;
	}
}

class IdlFunctionAttrCode
{
	static string createServerInterfaceCode(FunctionAttr FunctionAttrInterface, string inerfaceName)
	{
		auto strings = appender!string();

		formattedWrite(strings, "\tvoid %sInterface(RpcRequest req){\n\n", FunctionAttrInterface.funcName);
		formattedWrite(strings, "\t\tauto resp = new RpcResponse(req);\n\n");

		foreach(k,v ;FunctionAttrInterface.funcArgMap)
		{
			formattedWrite(strings, IdlFunctionArgCode.createServerCode(v));
		}
		
		formattedWrite(strings, "\n\n");
		
		auto funcArgsStrirngs = appender!string();

		for(int i = 0; i < FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length-1)
				formattedWrite(funcArgsStrirngs, "%s", v.getVarName);
			else
				formattedWrite(funcArgsStrirngs, "%s, ", v.getVarName);
		}
		
		formattedWrite(strings, "\t\treq.pop(%s);\n\n", replaceAll(funcArgsStrirngs.data, regex(`\,\s*\,`), ", "));
	
		funcArgsStrirngs = appender!string();

		for(int i = 0; i< FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length -1 )
				formattedWrite(funcArgsStrirngs, "%s", v.getVarName);
			else
				formattedWrite(funcArgsStrirngs, "%s, ", v.getVarName);
		}



		formattedWrite(strings, "\t\t%s %s;\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getVarName);

		formattedWrite(strings, "\t\t%s = (cast(Rpc%sService)this).%s(%s);\n\n", FunctionAttrInterface.retValue.getVarName, inerfaceName, FunctionAttrInterface.getFuncName, funcArgsStrirngs.data);

		funcArgsStrirngs = appender!string();
		formattedWrite(funcArgsStrirngs, "%s", FunctionAttrInterface.retValue.getVarName);

		formattedWrite(strings, "\t\tresp.push(%s);\n\n", replaceAll(funcArgsStrirngs.data, regex(`\,\s*\,|\,\s$`), ""));
		formattedWrite(strings, "\t\trpImpl.response(resp);\n");

		formattedWrite(strings, "\t}\n\n\n\n");
		
		return strings.data;
	}
	
	static string createServerServiceCode(FunctionAttr FunctionAttrInterface)
	{
		auto strings = appender!string();
		
		auto funcArgsStrirngs = appender!string();
		
		for(int i = 0; i< FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length -1 )
				formattedWrite(funcArgsStrirngs, "%s %s", v.getTypeName, v.getVarName);
			else
				formattedWrite(funcArgsStrirngs, "%s %s, ", v.getTypeName, v.getVarName);
		}

		formattedWrite(strings, "\t%s %s(%s){\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcArgsStrirngs.data);
		formattedWrite(strings, "\t\t%s %sRet;\n\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getTypeName);
		formattedWrite(strings, "\t\treturn %sRet;\n\t}\n\n\n\n", FunctionAttrInterface.retValue.getTypeName);

		return strings.data;
	}



	static string createClientServiceCode(FunctionAttr FunctionAttrInterface)
	{
		auto strings = appender!string();
		
		auto funcArgsStrirngs = appender!string();
		
		for(int i = 0; i< FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length -1 )
				formattedWrite(funcArgsStrirngs, "%s %s", v.getTypeName, v.getVarName);
			else
				formattedWrite(funcArgsStrirngs, "%s %s, ", v.getTypeName, v.getVarName);
		}

		auto funcValuesArgsStrirngs = appender!string();

		for(int i = 0; i< FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length -1 )
				formattedWrite(funcValuesArgsStrirngs, "%s", v.getVarName);
			else
				formattedWrite(funcValuesArgsStrirngs, "%s, ", v.getVarName);
		}


			formattedWrite(strings, "\t%s %s(%s){\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcArgsStrirngs.data);
			formattedWrite(strings, "\t\t%s ret = super.%sInterface(%s);\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcValuesArgsStrirngs.data);
			formattedWrite(strings, "\t\treturn ret;\n");
			formattedWrite(strings, "\t}\n\n\n");


			formattedWrite(strings, "\tvoid %s(%s, Rpc%sCallback rpcCallback){\n\n", 
			FunctionAttrInterface.funcName, funcArgsStrirngs.data, FunctionAttrInterface.funcName);
			formattedWrite(strings, "\t\tsuper.%sInterface(%s, rpcCallback);\n", FunctionAttrInterface.funcName, funcValuesArgsStrirngs.data);
			formattedWrite(strings, "\t}\n\n\n");

		return strings.data;
	}



	static string createClientInterfaceCode(FunctionAttr FunctionAttrInterface, string inerfaceName)
	{
		auto strings = appender!string();

		auto funcArgsStrirngs = appender!string();
		
		for(int i = 0; i< FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length -1 )
				formattedWrite(funcArgsStrirngs, "%s %s", v.getTypeName, v.getVarName);
			else
				formattedWrite(funcArgsStrirngs, "%s %s, ", v.getTypeName, v.getVarName);
		}

		auto funcArgsStructStrirngs = appender!string();
		
		for(int i = 0; i < FunctionAttrInterface.funcArgMap.length; i++)
		{
			auto v = FunctionAttrInterface.funcArgMap[i];
			
			if(i == FunctionAttrInterface.funcArgMap.length-1)
				formattedWrite(funcArgsStructStrirngs, "%s", v.getVarName);
			else
				formattedWrite(funcArgsStructStrirngs, "%s, ", v.getVarName);
		}



		formattedWrite(strings, "\t%s %sInterface(%s, string bindFunc = __FUNCTION__){\n\n", 
								FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcArgsStrirngs.data);
		formattedWrite(strings, "\t\tauto req = new RpcRequest;\n\n");
		formattedWrite(strings, "\t\treq.push(%s);\n\n", replaceAll(funcArgsStructStrirngs.data, regex(`\,\s*\,`), ", "));
		formattedWrite(strings, "\t\tRpcResponse resp = rpImpl.syncCall(req, bindFunc);\n\n");
		formattedWrite(strings, "\t\tif(resp.getStatus == RESPONSE_STATUS.RS_OK){\n");
		formattedWrite(strings, "\t\t\t%s %s;\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\tresp.pop(%s);\n\n", FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\treturn %s;\n\t\t}else{\n", FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\tthrow new Exception(\"rpc sync call error, function:\" ~ bindFunc);\n\t\t}\n");
		formattedWrite(strings, "\t}\n\n\n");



		formattedWrite(strings, "\talias Rpc%sCallback = void delegate(%s);\n\n", FunctionAttrInterface.funcName, FunctionAttrInterface.retValue.getTypeName);
		formattedWrite(strings, "\tvoid %sInterface(%s, Rpc%sCallback rpcCallback, string bindFunc = __FUNCTION__){\n\n", 
								FunctionAttrInterface.funcName, funcArgsStrirngs.data, FunctionAttrInterface.funcName);
		formattedWrite(strings, "\t\tauto req = new RpcRequest;\n\n");
		formattedWrite(strings, "\t\treq.push(%s);\n\n", replaceAll(funcArgsStructStrirngs.data, regex(`\,\s*\,`), ", "));
		formattedWrite(strings, "\t\trpImpl.asyncCall(req, delegate(RpcResponse resp){\n\n");
		formattedWrite(strings, "\t\t\tif(resp.getStatus == RESPONSE_STATUS.RS_OK){\n\n");
		formattedWrite(strings, "\t\t\t\t%s %s;\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\t\tresp.pop(%s);\n\n", FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\t\trpcCallback(%s);\n", FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\t}else{\n\t\t\t\tthrow new Exception(\"rpc sync call error, function:\" ~ bindFunc);\n\t\t\t}}, bindFunc);\n");
		formattedWrite(strings, "\t}\n\n\n");
		
		return strings.data;
	}
}


class idl_inerface_dlang_code
{
	static string createServerCodeForInterface(IdlParseInterface idlInterface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "abstract class Rpc%sInterface{ \n\n", idlInterface.interfaceName);
		formattedWrite(strings, "\tthis(RpcServer rpServer){ \n");
		formattedWrite(strings, "\t\trpImpl = new RpcServerImpl!(Rpc%sService)(rpServer); \n", idlInterface.interfaceName);
		
		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, "\t\trpImpl.bindRequestCallback(\"%s\", &this.%sInterface); \n\n", v.getFuncName, v.getFuncName);
		}
		
		formattedWrite(strings, "\t}\n\n");

		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, IdlFunctionAttrCode.createServerInterfaceCode(v, idlInterface.interfaceName));
		}
		
		formattedWrite(strings, "\tRpcServerImpl!(Rpc%sService) rpImpl;\n}\n\n\n", idlInterface.interfaceName);
		
		return strings.data;
	}


	static string createServerCodeForService(IdlParseInterface idlInterface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "class Rpc%sService: Rpc%sInterface{\n\n", idlInterface.interfaceName, idlInterface.interfaceName);
		formattedWrite(strings, "\tthis(RpcServer rpServer){\n");
		formattedWrite(strings, "\t\tsuper(rpServer);\n");
		formattedWrite(strings, "\t}\n\n");
		
		
		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, IdlFunctionAttrCode.createServerServiceCode(v));
		}
		
		formattedWrite(strings,"}\n\n\n\n");

		return strings.data;
	}


	static string createClientCodeForInterface(IdlParseInterface idlInterface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "abstract class Rpc%sInterface{ \n\n", idlInterface.interfaceName);
		formattedWrite(strings, "\tthis(RpcClient rpClient){ \n");
		formattedWrite(strings, "\t\trpImpl = new RpcClientImpl!(Rpc%sService)(rpClient); \n", idlInterface.interfaceName);
		formattedWrite(strings, "\t}\n\n");
		
		
		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, IdlFunctionAttrCode.createClientInterfaceCode(v, idlInterface.interfaceName));
		}
		
		formattedWrite(strings, "\tRpcClientImpl!(Rpc%sService) rpImpl;\n}\n\n\n", idlInterface.interfaceName);
		
		return strings.data;
	}


	static string createClientCodeForService(IdlParseInterface idlInterface)
	{
		auto strings = appender!string();

		formattedWrite(strings, "class Rpc%sService: Rpc%sInterface{\n\n", idlInterface.interfaceName, idlInterface.interfaceName);
		formattedWrite(strings, "\tthis(RpcClient rpClient){\n");
		formattedWrite(strings, "\t\tsuper(rpClient);\n");
		formattedWrite(strings, "\t}\n\n");
		
		
		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, IdlFunctionAttrCode.createClientServiceCode(v));
		}
		
		formattedWrite(strings, "}\n\n\n\n");

		return strings.data;
	}

}


