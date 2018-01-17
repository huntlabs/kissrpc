                 

module kissrpc.RpcBuild;

public import kissrpc.RpcCodec;
import kissrpc.RpcConstant;

import std.traits;
import std.format;
import std.stdio;
import std.typetuple;
import std.experimental.logger.core;

enum RpcAction;


mixin template MakeRpc(string moduleName = __MODULE__)
{
	mixin RpcDynamicCallFun!(typeof(this),moduleName);
}

mixin template RpcDynamicCallFun(T,string moduleName)
{
public:
	mixin("static import " ~ moduleName ~ ";");
	pragma(msg,createRpcCallFun!(T,moduleName));
	mixin(createRpcCallFun!(T,moduleName));
	shared static this(){
		assert(BaseTypeTuple!T.length >= 2,"rpc class must inherit rpc interface !!!");
		mixin(__creteRpcMap!(T,moduleName, BaseTypeTuple!T[1].stringof));
	}
}

string createRpcCallFun(T, string moduleName)()
{
	string str = "ubyte __RPCCALL__(string funName, ubyte[] paramData, ubyte protocol, ref ubyte[] returnData) {";
	str ~= "\n\twriteln(\"<<<===== __RPCCALL__ \",moduleName ~ \".\" ~ T.stringof ~\".\" ~ funName ~ \"=====>>>\");";
	str ~= "\n\tubyte ret = RpcProcCode.Success;";
	str ~= "\n\tswitch(funName) {";
	foreach(memberName; __traits(allMembers, T))
	{
		static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
		{
			foreach (t;__traits(getOverloads,T,memberName)) 
			{
				static if(hasUDA!(t,RpcAction))
				{
					alias ParameterTypeTuple!t ParameterTypes;
					alias ReturnType!t  RT;
					str ~="\n\t\tcase \""~memberName~"\": {";
					static if (is(RT == void)) {
						static if (ParameterTypes.length == 0) {
							str ~= "\n\t\t\t"~memberName~"();";
						}
						else static if (ParameterTypes.length > 1) {
							//TODO
							str ~="\n\t\t\treturn RpcProcCode.ParamsCountError;";
						}
						else {
							str ~= "\n\t\t\t"~getParamsTypes!(ParameterTypes)()~" params;";
							str ~="\n\t\t\tret = RpcCodec.decodeBuffer!("~getParamsTypes!(ParameterTypes)()~")(paramData,protocol,params);";
							str ~="\n\t\t\tif(ret != RpcProcCode.Success)";
							str ~="\n\t\t\t\treturn ret;";
							str ~="\n\t\t\t"~memberName~"("~params~");";
						}
					}
					else {
						static if (ParameterTypes.length == 0) {
							str ~= "\n\t\t\tauto backData = "~memberName~"();";
						}
						else static if (ParameterTypes.length > 1) {
							//TODO
							str ~="\n\t\t\treturn RpcProcCode.ParamsCountError;";
						}
						else {
							str ~= "\n\t\t\t"~getParamsTypes!(ParameterTypes)()~" params;";
							str ~="\n\t\t\tret = RpcCodec.decodeBuffer!("~getParamsTypes!(ParameterTypes)()~")(paramData,protocol,params);";
							str ~="\n\t\t\tif(ret != RpcProcCode.Success)";
							str ~="\n\t\t\t\treturn ret;";
							str ~="\n\t\t\tauto backData = "~memberName~"(params);";
						}
						str ~= "\n\t\t\tret = RpcCodec.encodeBuffer!(typeof(backData))(backData, protocol, returnData);";
						str ~="\n\t\t\tif(ret != RpcProcCode.Success)";
						str ~="\n\t\t\t\treturn ret;";
					}
					str ~="\n\t\t}";
					str ~="\n\t\tbreak;";
				}
			}
		}
	}
	str ~= "\n\t\tdefault : {";
	str ~= "\n\t\t\tret = RpcProcCode.NoFunctionName;";
	str ~= "\n\t\t}";
	str ~= "\n\t}";
	str ~= "\n\treturn ret;";
	str ~= "\n}";
	return str;
}

string getParamsTypes(Types...)() {
	string ret;
	foreach(i, v; Types) {
		if (i == 0) {
			ret = v.stringof;
			break;
		}
	}
	return ret;
}

string  __creteRpcMap(T, string moduleName, string interfaceName)()
{
	string str = "";
	foreach(memberName; __traits(allMembers, T)) {
		static if (is(typeof(__traits(getMember,  T, memberName)) == function) ) {
			foreach (t;__traits(getOverloads,T,memberName)) {
				static if(hasUDA!(t, RpcAction) ) {
					str ~= "\n\taddRpcFunction(\"" ~ InterfacesTuple!T[0].stringof ~ "." ~ memberName  ~ "\",&callHandler!(T,\"" ~ memberName ~ "\"));\n";
				}
			}
		}
	}
	return str;
}




ubyte callHandler(T,string fun)(ubyte[] paramData, ubyte protocol, ref ubyte[] returnData, ref string msg)
{
	T handler = new T();
	ubyte code = RpcProcCode.Success;
	try {
		code = handler.__RPCCALL__(fun, paramData, protocol, returnData);
		if (code == RpcProcCode.NoFunctionName)
			msg = "can not find function name : " ~ fun;
		else if(code == RpcProcCode.DecodeFailed) 
			msg = "decode failed : " ~ fun;
		else if(code == RpcProcCode.EncodeFailed)
			msg = "encode failed : " ~ fun;
	}
	catch (Exception e) {
		code = RpcProcCode.FunctionError;
		msg = e.toString();
		log(e);
	}
	msg = "success";
	return code;
}




HandleRpcFunction getRpcFunction(string str)
{
	if(!_init)
		_init = true;
	return __RpcFunctionList.get(str,null);
}


void addRpcFunction(string str, HandleRpcFunction fun)
{
	if(!_init) {
		writeln("addRpcFunction : ", str);
		__RpcFunctionList[str] = fun;
	}
}

alias HandleRpcFunction = ubyte function(ubyte[] paramData, ubyte protocol, ref ubyte[] returnData, ref string msg);
private:
__gshared bool _init = false;
__gshared HandleRpcFunction[string]  __RpcFunctionList;


