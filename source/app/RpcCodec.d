

module kissrpc.RpcCodec;

import kissrpc.RpcConstant;
import kissrpc.KissRpcPacket;

import std.traits;
import std.string;
import std.typecons;
import flatbuffers;
import std.stdio;


class RpcCodec {

public:
    static ubyte decodeBuffer(T)(ubyte[] data, ubyte protocol, ref T t) {
        ubyte ret = RpcProcCode.Success;
        if (protocol == RpcProtocol.FlatBuffer) {
            mixin(
                "auto fb = "~T.stringof~"Fb.getRootAs"~T.stringof~"Fb(new ByteBuffer(data));"~
                "\n\tfbConvertStruct!(T,typeof(fb))(t,fb);"
            );
        }
        return ret;
    }

    static ubyte encodeBuffer(T)(T t, ubyte protocol, ref ubyte[] data) {
        ubyte ret = RpcProcCode.Success;
        if (protocol == RpcProtocol.FlatBuffer) {
            mixin(
                "classConvertFbData!("~T.stringof~"Fb,"~T.stringof~")(t,data);"
            );
        }
        return ret;
    }

    //D flatbuffer struct convert to sample struct clsss
    static void fbConvertStruct(D,S)(ref D des, S src) {
        static if (!is(typeof(des) == struct) && !isArray!(typeof(des))) {
            des = src;
        }
        else {
            foreach(memberName; __traits(allMembers, D)) {
                alias curType = typeof(__traits(getMember,  des, memberName));
                static if (is (curType == struct)) {
                    fbConvertStruct!(curType, typeof(__traits(getMember,  src, memberName)))(__traits(getMember,  des, memberName), __traits(getMember,  src, memberName));
                }
                else static if (!isArray!(curType)) {
                    __traits(getMember,  des, memberName) = cast(curType)__traits(getMember,  src, memberName);
                }
                else {
                    static if (is(curType == string)) {
                        mixin("des."~memberName~" = "~"src."~memberName~";\n\t");
                    }
                    else {
                        mixin(
                            "des."~memberName~".length = src."~memberName~".length;\n\t"~
                            "foreach(k, v; src."~ memberName ~") { \n\t"~ 
                            "fbConvertClass!(typeof(des."~memberName~"[k]), typeof(v))(des."~memberName~"[k], v);\n\t"~
                            "}\n\t"
                        );
                    }
                }
            }
        }
    } 



    static void classConvertFbData(D,S)(S src, ref ubyte[] data) {
       
        
        mixin("auto builder = new FlatBufferBuilder(512);\n\t");
        mixin(paramsInit!(S)());
        // pragma(msg,"auto builder = new FlatBufferBuilder(512);\n\t");
        // pragma(msg,paramsInit!(S)());
        

        foreach(memberName; __traits(allMembers, S)) {
            alias srcType = typeof(__traits(getMember, S, memberName));
            alias desType = typeof(__traits(getMember, D, memberName));

            static if (is(srcType == struct)) {
            }
            else static if (isArray!(srcType)) {
                static if (is(srcType == string)) {
                    mixin(memberName~"_value = setFbString(src."~ memberName~",builder);\n\t");
                    // pragma(msg,memberName~"_value = setFbString(src."~ memberName~",builder);\n\t");
                }
                else {
                    mixin(memberName~"_value = setFbVector!(\""~getRealName(D.stringof)~"\","~getRealType(desType.stringof)~","~srcType.stringof~",\""~getRealName(memberName)~"\")(src."~ memberName~",builder);");
                    // pragma(msg,memberName~"_value = setFbVector!(\""~getRealName(D.stringof)~"\","~getRealType(desType.stringof)~","~srcType.stringof~",\""~getRealName(memberName)~"\")(src."~ memberName~",builder);");
                }
            }
            else {
                mixin(memberName~"_value = cast("~desType.stringof~")setFbCommon!("~srcType.stringof~")(src."~ memberName~");");
                // pragma(msg,memberName~"_value = cast("~desType.stringof~")setFbCommon!("~srcType.stringof~")(src."~ memberName~");");
            }
        }

        mixin(D.stringof~".start"~D.stringof~"(builder);\n\t");
        // pragma(msg,D.stringof~".start"~D.stringof~"(builder);\n\t");
        foreach(memberName; __traits(allMembers, S)) {
            alias srcType = typeof(__traits(getMember, S, memberName));
            alias desType = typeof(__traits(getMember, D, memberName));
            static if (is(srcType == struct)) {
                mixin(D.stringof~".add"~getRealName(memberName)~"(builder,setFbStruct!("~getRealName(desType.stringof)~","~srcType.stringof~")(src."~ memberName~",builder));\n\t");
                // pragma(msg,D.stringof~".add"~getRealName(memberName)~"(builder,setFbStruct!("~getRealName(desType.stringof)~","~srcType.stringof~")(src."~ memberName~",builder));\n\t");
            }
            else {
                mixin(D.stringof~".add"~getRealName(memberName)~"(builder,"~memberName~"_value);\n\t");
                // pragma(msg,D.stringof~".add"~getRealName(memberName)~"(builder,"~memberName~"_value);\n\t");
            }
        }
        mixin("auto mloc ="~D.stringof~".end"~D.stringof~"(builder);\n\t");
        mixin("builder.finish(mloc);\n\t");
        mixin("data = builder.sizedByteArray();");
        // pragma(msg,"auto mloc ="~D.stringof~".end"~D.stringof~"(builder);\n\t");
        // pragma(msg,"builder.finish(mloc);\n\t");
        // pragma(msg,"data = builder.sizedByteArray();");

    }

private:

    static string paramsInit(D)() {
        string str;
        foreach(memberName; __traits(allMembers, D)) {
            alias curType = typeof(__traits(getMember, D, memberName));
            static if (isSomeChar!curType) {
                str ~= "uint "~memberName~"_value;\n\t";
            }
            static if (isBasicType!(curType)) {
                static if (is(typeof(__traits(getMember, D, memberName)) == enum)) {
                    str ~= "byte "~memberName~"_value;\n\t";
                }
                else {
                    str ~= typeof(__traits(getMember, D, memberName)).stringof~" "~memberName~"_value;\n\t";
                }
            }
            else {
                str ~= "uint "~memberName~"_value;\n\t";
            }
        }
        return str;
    }

    static string makeStructParams(D,T)() {
        string str;	
        str = "ret = "~D.stringof~".create"~D.stringof~"(builder, ";
        foreach(index, memberName; __traits(allMembers, T)) {
            alias srcType = typeof(__traits(getMember, T, memberName));
            alias desType = typeof(__traits(getMember, D, memberName));
            if (index != 0) {
                str ~= ", ";
            }
            static if (is(srcType == struct)) {
                str ~= "setFbStruct!(\""~getRealName(Name)~"\","~srcType.stringof~","~getRealName(desType.stringof)~")(src."~memberName~", builder)";
            }
            else static if(isArray!(srcType)) {
                static if (is(srcType == string)) {
                    str ~= "setFbString(src."~memberName~", builder)";
                }
                else {
                    str ~= "setFbVector!("~getRealName(desType.stringof)~", "~getRealName(desType.stringof)~", "~getRealName(memberName)~")(src."~memberName~", builder)";
                }
            }
            else {
                str ~= "setFbCommon!("~srcType.stringof~")(src."~memberName~")";
            }
        }
        str ~= ");\n\t";
        return str;
    }

    static uint setFbStruct(D,T)(T src, FlatBufferBuilder builder) {
        uint ret;
        mixin(makeStructParams!(D,T)());
        return ret;
    }

    static uint setFbVector(string fatherName, D, T, string Name)(T src, FlatBufferBuilder builder) {
        uint ret;
        static if (isBasicType!(D)) {
            T data;
        }
        else {
            uint[] data;
        }
        foreach(index ,value; src) {
            static if (is(typeof(value) == struct)) {
                data ~= setFbStruct!(D,typeof(value))(value, builder);
            }
            else static if(isArray!(typeof(value))) {
                static if (is(typeof(value) == string)) {
                    data ~= setFbString(value, builder);
                }
                else {
                    //二位数组不支持
                }
            }
            else {
                data ~= setFbCommon!(typeof(value))(value);
            }
        }
        mixin("ret = "~fatherName~".create"~Name~"Vector(builder,data);\n\t");
        return ret;
    }

    static uint setFbString(string src, FlatBufferBuilder builder) {
        return builder.createString(src);
    }

    static T setFbCommon(T)(T src) {
        return src;
    }

    static string getRealName(string str) {
        if (indexOf(str, "Nullable!(") != -1) {
            return capitalize(str[indexOf(str, "Nullable!(")+10..$-1]);
        }
        if(indexOf(str, "Nullable!") != -1) {
            return capitalize(str[indexOf(str, "Nullable!")+9..$]);
        }
        else if(indexOf(str, "\"") != -1) {
            return capitalize(str[indexOf(str, "\"")+1..$-4]);
        }
        else {
            return capitalize(str);
        }
    }

    static string getRealType(string str) {
        if (indexOf(str, ",") != -1) {
            return str[indexOf(str, ",")+1 .. indexOf(str, ",")+indexOf(str[indexOf(str, ",")+1..$], ",")+1];
        }
        return str;
    }



}