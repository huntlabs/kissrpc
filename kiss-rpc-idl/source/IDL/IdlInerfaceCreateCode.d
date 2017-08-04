module IDL.IdlInerfaceCreateCode;

import std.array : appender;
import std.format;
import std.regex;
import std.stdio;

import IDL.IdlParseInterface;
import IDL.IdlStructCreateCode;
import IDL.IdlUnit;
import IDL.IdlSymbol;
import IDL.IdlParseStruct;

class IdlFunctionArgCode
{
	static string createServerCode(MemberAttr functionInerface)
	{
		auto strings = appender!string();
		
		auto dlangVarName = idlDlangVariable.get(functionInerface.typeName, null);
		
		if(dlangVarName is null)
		{
			auto dlangStructName = idlStructList.get(functionInerface.typeName, null);

			if(dlangStructName is null)
			{
				throw new Exception("not parse symbol for struct name: " ~ functionInerface.typeName);
			}
		}

		formattedWrite(strings, "\t\t%s %s;\n", functionInerface.typeName, functionInerface.getVarName);

		return strings.data;
	}


	static string createClientCode(MemberAttr functionInerface)
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
		
		formattedWrite(strings, "\t\t %s %s;\n", functionInerface.typeName, functionInerface.getVarName);
		
		return strings.data;
	}
}

class IdlFunctionAttrCode
{
	static string createServerInterfaceCode(FunctionAttr FunctionAttrInterface, string inerfaceName)
	{
		auto strings = appender!string();

		formattedWrite(strings, "\tvoid %sInterface(RpcRequest req){\n\n", FunctionAttrInterface.funcName);

		formattedWrite(strings, "\t\tubyte[] flatBufBytes;\n\n");

		formattedWrite(strings, "\t\tauto resp = new RpcResponse(req);\n");
		formattedWrite(strings, "\t\treq.pop(flatBufBytes);\n\n");
		formattedWrite(strings, "\t\tauto %sFB = %sFB.getRootAs%sFB(new ByteBuffer(flatBufBytes));\n", FunctionAttrInterface.funcArgMap.getVarName, FunctionAttrInterface.funcArgMap.getTypeName, FunctionAttrInterface.funcArgMap.getTypeName);

		formattedWrite(strings, "\t\t%s %s;\n\n", FunctionAttrInterface.funcArgMap.getTypeName, FunctionAttrInterface.funcArgMap.getVarName);

		formattedWrite(strings, "\t\t//input flatbuffer code for %sFB class\n\n\n\n", FunctionAttrInterface.funcArgMap.getTypeName);
		formattedWrite(strings, "\t\t%s\n\n", IdlParseStruct.createDeserializeCodeForFlatbuffer(idlStructList[FunctionAttrInterface.funcArgMap.getTypeName], FunctionAttrInterface.funcArgMap.getVarName, FunctionAttrInterface.funcArgMap.getVarName~"FB"));


		formattedWrite(strings, "\t\tauto %s = (cast(Rpc%sService)this).%s(%s);\n\n", FunctionAttrInterface.retValue.getVarName, inerfaceName, FunctionAttrInterface.getFuncName, FunctionAttrInterface.funcArgMap.getVarName);

		formattedWrite(strings, "\t\tauto builder = new FlatBufferBuilder(512);\n");

		formattedWrite(strings, "\t\t//input flatbuffer code for %sFB class\n\n", FunctionAttrInterface.retValue.getTypeName);
		formattedWrite(strings, "\t\t%s\n\n", IdlParseStruct.createSerializeCodeForFlatbuffer(idlStructList[FunctionAttrInterface.retValue.getTypeName], FunctionAttrInterface.retValue.getVarName));

		formattedWrite(strings, "\t\tbuilder.finish(%sPos);\n\n", FunctionAttrInterface.retValue.getVarName);

		formattedWrite(strings, "\t\tresp.push(builder.sizedByteArray);\n\n");
		formattedWrite(strings, "\t\trpImpl.response(resp);\n");

		formattedWrite(strings, "\t}\n\n\n\n");
		
		return strings.data;
	}
	
	static string createServerServiceCode(FunctionAttr FunctionAttrInterface)
	{
		auto strings = appender!string();
		
		auto funcArgsStrirngs = appender!string();

		auto v = FunctionAttrInterface.funcArgMap;

		formattedWrite(funcArgsStrirngs, "%s %s", v.getTypeName, v.getVarName);

		formattedWrite(strings, "\t%s %s(%s){\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcArgsStrirngs.data);
		formattedWrite(strings, "\t\t%s %sRet;\n", FunctionAttrInterface.retValue.getTypeName, stringToLower(FunctionAttrInterface.retValue.getTypeName, 0));
		formattedWrite(strings, "\t\t//input service code for %s class\n\n\n\n", FunctionAttrInterface.retValue.getTypeName);

		formattedWrite(strings, "\t\treturn %sRet;\n\t}\n\n\n\n", stringToLower(FunctionAttrInterface.retValue.getTypeName, 0));

		return strings.data;
	}


	static string createClientServiceCode(FunctionAttr FunctionAttrInterface)
	{
			auto strings = appender!string();
			
			auto funcArgsStrirngs = appender!string();

			auto v = FunctionAttrInterface.funcArgMap;
			formattedWrite(funcArgsStrirngs, "%s %s", v.getTypeName, v.getVarName);
			

			auto funcValuesArgsStrirngs = appender!string();

			v = FunctionAttrInterface.funcArgMap;

			formattedWrite(funcValuesArgsStrirngs, "%s", v.getVarName);
	

			formattedWrite(strings, "\t%s %s(%s, const RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS){\n\n", 
							FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcArgsStrirngs.data);

			formattedWrite(strings, "\t\t%s ret = super.%sInterface(%s, compressType, secondsTimeOut);\n", 
							FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcValuesArgsStrirngs.data);
			
			formattedWrite(strings, "\t\treturn ret;\n");
			formattedWrite(strings, "\t}\n\n\n");


			formattedWrite(strings, "\tvoid %s(%s, Rpc%sCallback rpcCallback, const RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS){\n\n", 
			FunctionAttrInterface.funcName, funcArgsStrirngs.data, FunctionAttrInterface.funcName);
			formattedWrite(strings, "\t\tsuper.%sInterface(%s, rpcCallback, compressType, secondsTimeOut);\n", FunctionAttrInterface.funcName, funcValuesArgsStrirngs.data);
			formattedWrite(strings, "\t}\n\n\n");

		return strings.data;
	}



	static string createClientInterfaceCode(FunctionAttr FunctionAttrInterface, string inerfaceName)
	{
		auto strings = appender!string();

		auto funcArgsStrirngs = appender!string();

		auto v = FunctionAttrInterface.funcArgMap;
		formattedWrite(funcArgsStrirngs, "%s %s", v.getTypeName, v.getVarName);

		auto funcArgsStructStrirngs = appender!string();
		v = FunctionAttrInterface.funcArgMap;
		formattedWrite(funcArgsStructStrirngs, "%s", v.getVarName);

		formattedWrite(strings, "\t%s %sInterface(const %s, const RPC_PACKAGE_COMPRESS_TYPE compressType, const int secondsTimeOut, const size_t funcId = %s){\n\n", 
								FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.funcName, funcArgsStrirngs.data, FunctionAttrInterface.funcHash);

		formattedWrite(strings, "\t\tauto builder = new FlatBufferBuilder(512);\n\n");
		formattedWrite(strings, "\t\t//input flatbuffer code for %sFB class\n\n\n\n\n", v.typeName);
		formattedWrite(strings, "\t\t%s\n\n", IdlParseStruct.createSerializeCodeForFlatbuffer(idlStructList[v.typeName], v.varName));
		formattedWrite(strings, "\t\tbuilder.finish(%sPos);\n\n", v.varName);


		formattedWrite(strings, "\t\tauto req = new RpcRequest(compressType, secondsTimeOut);\n\n");
		formattedWrite(strings, "\t\treq.push(builder.sizedByteArray);\n\n");
		formattedWrite(strings, "\t\tRpcResponse resp = rpImpl.syncCall(req, RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, funcId);\n\n");
		formattedWrite(strings, "\t\tif(resp.getStatus == RESPONSE_STATUS.RS_OK){\n\n");
		formattedWrite(strings, "\t\t\tubyte[] flatBufBytes;\n");
		formattedWrite(strings, "\t\t\tresp.pop(flatBufBytes);\n\n");
		formattedWrite(strings, "\t\t\tauto %sFB = %sFB.getRootAs%sFB(new ByteBuffer(flatBufBytes));\n", FunctionAttrInterface.retValue.getVarName, FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getTypeName);

		formattedWrite(strings, "\t\t\t%s %s;\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\t//input flatbuffer code for %sFB class\n\n\n\n\n", FunctionAttrInterface.retValue.getTypeName);
		formattedWrite(strings, "\t\t%s\n\n", IdlParseStruct.createDeserializeCodeForFlatbuffer(idlStructList[FunctionAttrInterface.retValue.getTypeName], FunctionAttrInterface.retValue.getVarName, FunctionAttrInterface.retValue.getVarName~"FB"));
		formattedWrite(strings, "\t\t\treturn %s;\n\t\t}else{\n", FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\tthrow new Exception(\"rpc sync call error, function:\" ~ RpcBindFunctionMap[funcId]);\n\t\t}\n");
		formattedWrite(strings, "\t}\n\n\n");



		formattedWrite(strings, "\talias Rpc%sCallback = void delegate(%s);\n\n", FunctionAttrInterface.funcName, FunctionAttrInterface.retValue.getTypeName);
		formattedWrite(strings, "\tvoid %sInterface(const %s, Rpc%sCallback rpcCallback, const RPC_PACKAGE_COMPRESS_TYPE compressType, const int secondsTimeOut, const size_t funcId = %s){\n\n", 
								FunctionAttrInterface.funcName, funcArgsStrirngs.data, FunctionAttrInterface.funcName, FunctionAttrInterface.funcHash);

		formattedWrite(strings, "\t\tauto builder = new FlatBufferBuilder(512);\n");
		formattedWrite(strings, "\t\t//input flatbuffer code for %sFB class\n\n\n\n\n", v.typeName);
		formattedWrite(strings, "\t\t%s\n\n", IdlParseStruct.createSerializeCodeForFlatbuffer(idlStructList[v.typeName], v.varName));
		formattedWrite(strings, "\t\tbuilder.finish(%sPos);\n", v.varName);


		formattedWrite(strings, "\t\tauto req = new RpcRequest(compressType, secondsTimeOut);\n\n");
		formattedWrite(strings, "\t\treq.push(builder.sizedByteArray);\n\n");
		formattedWrite(strings, "\t\trpImpl.asyncCall(req, delegate(RpcResponse resp){\n\n");
		formattedWrite(strings, "\t\t\tif(resp.getStatus == RESPONSE_STATUS.RS_OK){\n\n");
		formattedWrite(strings, "\t\t\t\tubyte[] flatBufBytes;\n");
		formattedWrite(strings, "\t\t\t\t%s %s;\n\n", FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\t\tresp.pop(flatBufBytes);\n\n");
		formattedWrite(strings, "\t\t\t\tauto %sFB = %sFB.getRootAs%sFB(new ByteBuffer(flatBufBytes));\n", FunctionAttrInterface.retValue.getVarName, FunctionAttrInterface.retValue.getTypeName, FunctionAttrInterface.retValue.getTypeName);

		formattedWrite(strings, "\t\t\t\t//input flatbuffer code for %sFB class\n\n\n\n\n", FunctionAttrInterface.retValue.getTypeName);
		formattedWrite(strings, "\t\t%s\n\n", IdlParseStruct.createDeserializeCodeForFlatbuffer(idlStructList[FunctionAttrInterface.retValue.getTypeName], FunctionAttrInterface.retValue.getVarName, FunctionAttrInterface.retValue.getVarName~"FB"));
		formattedWrite(strings, "\t\t\t\trpcCallback(%s);\n", FunctionAttrInterface.retValue.getVarName);
		formattedWrite(strings, "\t\t\t}else{\n\t\t\t\tthrow new Exception(\"rpc sync call error, function:\" ~ RpcBindFunctionMap[funcId]);\n\t\t\t}}, RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, funcId);\n", inerfaceName);
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
			formattedWrite(strings, "\t\trpImpl.bindRequestCallback(%s, &this.%sInterface); \n\n", v.funcHash, v.getFuncName);
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


		formattedWrite(strings, "\nclass Rpc%sService: Rpc%sInterface{\n\n", idlInterface.interfaceName, idlInterface.interfaceName);
		formattedWrite(strings, "\tthis(RpcServer rpServer){\n");

		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, "\t\tRpcBindFunctionMap[%s] = typeid(&Rpc%sService.%s).toString();\n", v.funcHash, idlInterface.interfaceName, v.funcName);
		}

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

		formattedWrite(strings, "\nclass Rpc%sService: Rpc%sInterface{\n\n", idlInterface.interfaceName, idlInterface.interfaceName);
		formattedWrite(strings, "\tthis(RpcClient rpClient){\n");

		foreach(k,v; idlInterface.functionList)
		{
			formattedWrite(strings, "\t\tRpcBindFunctionMap[%s] = typeid(&Rpc%sService.%s).toString();\n", v.funcHash, idlInterface.interfaceName, v.funcName);
		}


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


