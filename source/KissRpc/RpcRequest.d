module KissRpc.RpcRequest;

import KissRpc.Logs;
import KissRpc.Unit;
import KissRpc.Endian;
import KissRpc.RpcSocketBaseInterface;
import KissRpc.RpcResponse;


import std.stdio;
import std.traits;
import core.sync.semaphore;


alias  REQUEST_STATUS = RESPONSE_STATUS; 

class FuncArgValue(T)
{
	this(T t)
	{
		value = t;
	}

	this()
	{

	}

	T getValue()
	{
		return value;
	}

	ubyte[] toBytes()const
	{
		ubyte[] bytes;

		static if(isIntegral!T && (!is(Unqual!T == byte) && !is(Unqual!T == ubyte)))
		{
			bytes = new ubyte[value.sizeof];
			T bits = hostToNet(value);
			bytes[0 .. value.sizeof] = (cast(ubyte*)&bits)[0 .. value.sizeof];

		}else static if(isFloatingPoint!T){

			static if(is(Unqual!T == double) || is(Unqual!T == idouble))
			{
				 bytes = new ubyte[value.sizeof];
				auto bits = hostToNet(*cast(ulong*)(&value));
				bytes[0 .. value.sizeof] = (cast(ubyte*)&bits)[0 .. value.sizeof];
			}

			static if(is(Unqual!T == float) || is(Unqual!T == ifloat))
			{
				bytes = new ubyte[value.sizeof];

				auto bits = hostToNet(*cast(uint*)(&value));
				bytes[0 .. value.sizeof] = (cast(ubyte*)&bits)[0 .. value.sizeof];
			}
		}else static if(isSomeString!T)
		{
			bytes = new ubyte[value.length];
			bytes[0 .. value.length] = (cast(ubyte[])value)[0 .. value.length];
		
		}else static if(isSomeChar!T)
		{
			bytes = new ubyte[1];
			bytes[0] = cast(ubyte)(value);
		}else
		{

			logWarning("function argument is failed, type:%s",typeid(T).toString());
		}

		return bytes;
	}

	T fromBytes(const ubyte[] bytes)
	{
		static if(isIntegral!T && (!is(Unqual!T == byte) && !is(Unqual!T == ubyte)))
		{
			IntBuf!(T) bits;
			bits.bytes = bytes[0 .. bytes.length];
			value = netToHost(bits.value);
			
		}else static if(isFloatingPoint!T){
			IntBuf!(long) bits;
			bits.bytes = bytes[0 .. bytes.length];
			bits.value = netToHost(bits.value);
			value = *cast(T*)(&bits.value);

		}else static if(isSomeString!T)
		{
			value = cast(T)bytes;

		}else static if(isSomeChar!T)
		{
			value = cast(T)(bytes[0]);

		}else
		{
			logError("function argument is failed, type:%s", typeid(T).toString());
		}

		return value;
	}


private:
	T value;
}


class FuncArgTemplate
{
	this(){
	}

	void add(T)(T t)
	{

		static if(!isSomeString!(T)&& isDynamicArray!(T))
		{
			funcArg = cast(void *)new FuncArgValue!(ushort)(cast(ushort)t.length);
			typeName = "array";

		}else
		{
			funcArg = cast(void *)new FuncArgValue!(T)(t);
			typeName = typeid(t).toString();
		}
	}


	T get(T)() const
	{
		static if(!isSomeString!(T)&& isDynamicArray!(T))
		{
			auto arg = cast(FuncArgValue!(ushort)) funcArg;

			T arrayList;
			arrayList.length = arg.getValue;

			return arrayList;

		}else
		{
			auto arg = cast(FuncArgValue!(T)) funcArg;
			return arg.getValue();
		}
	}


	ubyte[] toBytes()const
	{
		switch(typeName)
		{
			case "int" :   return 	(cast(FuncArgValue!(int))   funcArg).toBytes(); 
			case "bool":   return 	(cast(FuncArgValue!(bool))  funcArg).toBytes();
			case "byte":   return 	(cast(FuncArgValue!(byte))  funcArg).toBytes();
			case "short":  return 	(cast(FuncArgValue!(short)) funcArg).toBytes();
			//case "void":   return 	(cast(FuncArgValue!(void))  funcArg).toBytes();
			case "long":   return 	(cast(FuncArgValue!(long))  funcArg).toBytes();
			case "ubyte":  return 	(cast(FuncArgValue!(ubyte)) funcArg).toBytes();
			case "ushort", "array": return 	(cast(FuncArgValue!(ushort)) funcArg).toBytes();
			case "uint" :  return 	(cast(FuncArgValue!(uint))  funcArg).toBytes();
			case "ulong":  return 	(cast(FuncArgValue!(ulong)) funcArg).toBytes();
			case "float":  return 	(cast(FuncArgValue!(float)) funcArg).toBytes();
			case "double": return 	(cast(FuncArgValue!(double)) funcArg).toBytes();
			//case "real":   return 	(cast(FuncArgValue!(real))  funcArg).toBytes();
			case "char":   return 	(cast(FuncArgValue!(char))  funcArg).toBytes();
			case "wchar":  return 	(cast(FuncArgValue!(wchar)) funcArg).toBytes();
			case "dchar":  return 	(cast(FuncArgValue!(dchar)) funcArg).toBytes();
			case "immutable(char)[]": return 	(cast(FuncArgValue!(immutable(char)[])) funcArg).toBytes();
			
			default: 
				logError("function argument is failed, type:%s", typeName);
		}
			
		return null;
	}

	T fromBytes(T)(const ubyte[] bytes)
	{
		funcArg = cast(void *)new FuncArgValue!(T)();

		FuncArgValue!(T) t = (cast(FuncArgValue!(T))funcArg);
		t.fromBytes(bytes);
		typeName = typeid(t.getValue()).toString();

		return t.getValue();
	}


	string getTypeString() const
	{
		return typeName;
	}

private:
	string typeName;
	void* funcArg;
}



class RpcRequest
{
	this(const RPC_PACKAGE_COMPRESS_TYPE type = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS)
	{
		timeOut = secondsTimeOut;
		timestamp = RPC_SYSTEM_TIMESTAMP;
		semaphore = new Semaphore;
		nonblock = true;
		compressType = type;
	}

	this(RpcRequest req)
	{
		this.baseSocket = req.baseSocket;
		this.funcName = req.funcName;
		this.sequeNum = req.sequeNum;
		this.nonblock = req.nonblock;
		this.compressType = req.compressType;
	}

	this(RpcSocketBaseInterface socket)
	{
		baseSocket = socket;
	}


	void push(T...)(T args)
	{
		foreach(i, ref arg; args)
		{
			static if(isBasicType!(T[i]) || isSomeString!(T[i]) || isDynamicArray!(T[i]))
			{
				auto argTemplate = new FuncArgTemplate;
				argTemplate.add(arg);
				funcArgList[argNum++] = argTemplate;

				static if(!isSomeString!(T[i]) && isDynamicArray!(T[i]))
				{
					if(arg.length > 0)
					{
						deWritefln("function:%s, request push array: %s:%s", funcName, typeid(arg), arg);

						foreach(ref r; arg)
						{
							this.push(r);
						}

					}else
					{
						logWarning("function:%s, request push array is null, %s:%s", funcName, typeid(arg), arg);
					}

				}else
				{
					static if(isStaticArray!(T[i]))
					{
						throw(new Exception("value type is static array!!, the array must be dynamic!! in type:"~typeid(arg).toString()));
					}

					deWritefln("function:%s, request push: %s:%s", funcName, typeid(arg), arg);
				}

			}else
			{
				deWritefln("function:%s, request push class: %s:%s", funcName, typeid(arg), arg);
				arg.createTypeTulple();

				foreach(ref v; arg.memberList)
				{
					this.push(v);
				}
			}
		}
	}



	bool pop(T...)(ref T args)
	{
		try{

			foreach(i, ref arg; args)
			{
				static if(isBasicType!(T[i]) || isSomeString!(T[i]) || isDynamicArray!(T[i]))
				{
					auto argTemplate = funcArgList[funcArgListIndex++];
					arg = argTemplate.get!(T[i]);

					static if(!isSomeString!(T[i]) && isDynamicArray!(T[i]))
					{
						if(arg.length > 0)
						{
							deWritefln("function:%s, request pop array: %s:%s", funcName, typeid(arg), arg);

							foreach(ref r; arg)
							{
								this.pop(r);
							}

						}else
						{
							logWarning("function:%s, request pop array is null, %s:%s", funcName, typeid(arg), arg);
						}

					}else
					{

						static if(isStaticArray!(T[i]))
						{
							throw(new Exception("value type is static array!!, the array must be dynamic!! in type:"~typeid(arg).toString()));
						}


						if(typeid(arg).toString() != argTemplate.typeName)
						{	
							throw(new Exception("value type is not match, in type:" ~ typeid(arg).toString()~", out type:" ~ argTemplate.getTypeString()));
						}

						deWritefln("function:%s, request pop: %s:%s", funcName, typeid(arg), arg);
					}


				}else
				{
					deWritefln("function:%s, request pop class: %s:%s", funcName, typeid(arg), arg);

					foreach(ref v; arg.memberList)
					{
						this.pop(v);
					}

					arg.restoreTypeTunlp();
				}
			}

		}catch(Exception e)
		{
			logWarning(e.msg);
			return false;
		}

		return true;
	}

	void bindFunc(string func)
	{
		funcName = func;
	}

	int getArgsNum()const
	{
		return argNum;
	}

	string getCallFuncName()const
	{
		return funcName;
	}

	auto getFunArgList()const
	{
		return funcArgList;
	}

	void setSocket(RpcSocketBaseInterface socket)
	{
		baseSocket = socket;
	}

	auto getSocket()
	{
		return baseSocket;
	}

	auto getTimestamp()const
	{
		return timestamp;
	}

	void setSequence(ulong seque)
	{
		sequeNum = seque;
	}

	auto getSequence()const
	{
		return sequeNum;
	}

	auto getTimeout()const
	{
		return timeOut;
	}

	void setStatus(RESPONSE_STATUS status)
	{
		response_status = status;
	}

	auto getStatus()const
	{
		return response_status;
	}

	auto getNonblock()const
	{
		return nonblock;
	}

	void setNonblock(bool isNonblock)
	{
		nonblock = isNonblock;
	}


	void addFuncArgTemplate(FuncArgTemplate tpl)
	{
		funcArgList[argNum++] = tpl;
	}

	void semaphoreWait()
	{
		nonblock = false;
		semaphore.wait();
	}

	void semaphoreRelease()
	{
		semaphore.notify();
	}

	RPC_PACKAGE_COMPRESS_TYPE getCompressType()
	{
		return compressType;
	}

	void setCompressType(RPC_PACKAGE_COMPRESS_TYPE type)
	{
		compressType = type;
	}

private:
	int argNum;
	int funcArgListIndex;

	RPC_PACKAGE_COMPRESS_TYPE compressType;

	RESPONSE_STATUS response_status;

	FuncArgTemplate[int] funcArgList;
	string funcName;
	RpcSocketBaseInterface baseSocket;
	Semaphore semaphore;

	bool nonblock;

	ulong timestamp;
	ulong timeOut;
	ulong sequeNum;
}
