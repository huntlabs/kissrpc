module KissRpc.rpc_request;
import std.stdio;
import std.traits;
import core.sync.semaphore;

import KissRpc.logs;
import KissRpc.unit;
import KissRpc.endian;
import KissRpc.rpc_socket_base_interface;
import KissRpc.rpc_response;


alias  REQUEST_STATUS = RESPONSE_STATUS; 

class func_arg_value(T)
{
	this(T t)
	{
		value = t;
	}

	this()
	{

	}

	T get_value() const
	{
		return value;
	}

	ubyte[] to_bytes()const
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
		}

		return bytes;
	}

	T from_bytes(const ubyte[] bytes)
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
		}

		return value;
	}


private:
	T value;
}


class func_arg_template
{
	this(){
	}

	void add(T)(T t)
	{
		func_arg = cast(void *)new func_arg_value!(T)(t);
		type_name = typeid(t).toString();
	}

	T get(T)() const
	{
		auto arg = cast(func_arg_value!(T)) func_arg;
		return arg.get_value();
	}

	ubyte[] to_bytes()const
	{
		switch(type_name)
		{
			case "int" :   return 	(cast(func_arg_value!(int))   func_arg).to_bytes(); 
			case "bool":   return 	(cast(func_arg_value!(bool))  func_arg).to_bytes();
			case "byte":   return 	(cast(func_arg_value!(byte))  func_arg).to_bytes();
			case "short":  return 	(cast(func_arg_value!(short)) func_arg).to_bytes();
			//case "void":   return 	(cast(func_arg_value!(void))  func_arg).to_bytes();
			case "long":   return 	(cast(func_arg_value!(long))  func_arg).to_bytes();
			case "ubyte":  return 	(cast(func_arg_value!(ubyte)) func_arg).to_bytes();
			case "ushort": return 	(cast(func_arg_value!(ushort)) func_arg).to_bytes();
			case "uint" :  return 	(cast(func_arg_value!(uint))  func_arg).to_bytes();
			case "ulong":  return 	(cast(func_arg_value!(ulong)) func_arg).to_bytes();
			case "float":  return 	(cast(func_arg_value!(float)) func_arg).to_bytes();
			case "double": return 	(cast(func_arg_value!(double)) func_arg).to_bytes();
			//case "real":   return 	(cast(func_arg_value!(real))  func_arg).to_bytes();
			case "char":   return 	(cast(func_arg_value!(char))  func_arg).to_bytes();
			case "wchar":  return 	(cast(func_arg_value!(wchar)) func_arg).to_bytes();
			case "dchar":  return 	(cast(func_arg_value!(dchar)) func_arg).to_bytes();
			case "immutable(char)[]": return 	(cast(func_arg_value!(immutable(char)[])) func_arg).to_bytes();

			default: 
				throw new Exception("convert to bytes fatal!! type:" ~ type_name);
		}
	}

	T from_bytes(T)(const ubyte[] bytes)
	{
		func_arg = cast(void *)new func_arg_value!(T)();

		func_arg_value!(T) t = (cast(func_arg_value!(T))func_arg);
		t.from_bytes(bytes);
		type_name = typeid(t.get_value()).toString();

		return t.get_value();
	}


	string get_type_string() const
	{
		return type_name;
	}

private:
	string type_name;
	void* func_arg;
}



class rpc_request
{
	this(const int seconds_time_out = RPC_REQUEST_TIMEOUT_SECONDS)
	{
		time_out = seconds_time_out;
		timestamp = RPC_SYSTEM_TIMESTAMP;
		semaphore = new Semaphore;
		nonblock = true;
	}

	this(rpc_request req)
	{
		this.base_socket = req.base_socket;
		this.func_name = req.func_name;
		this.seque_num = req.seque_num;
		this.nonblock = req.nonblock;
	}

	this(rpc_socket_base_interface socket)
	{
		base_socket = socket;
	}

	void push(T...)(T args)
	{
		foreach(i, arg; args)
		{
			de_writefln("function:%s, request push: %s:%s", func_name, typeid(arg), arg);
			auto arg_template = new func_arg_template;
			arg_template.add(arg);
			func_arg_list[arg_num++] = arg_template;
		}
	}

	bool pop(T...)(ref T args)
	{
		try{
			foreach(i, ref arg; args)
			{
				auto arg_template = func_arg_list[i];

				if(typeid(arg).toString() != arg_template.type_name)
				{	
					throw(new Exception("value type is not match, in type:" ~ typeid(arg).toString()~", out type:" ~ arg_template.get_type_string()));
				}

				arg = arg_template.get!(T[i]);
				de_writefln("function:%s, request pop: %s:%s", func_name, typeid(arg), arg);
			}

		}catch(Exception e)
		{
			log_warning(e.msg);
			return false;
		}

		return true;
	}

	void bind_func(string func)
	{
		func_name = func;
	}

	int get_args_num()const
	{
		return arg_num;
	}

	string get_call_func_name()const
	{
		return func_name;
	}

	auto get_fun_arg_list()const
	{
		return func_arg_list;
	}

	void set_socket(rpc_socket_base_interface socket)
	{
		base_socket = socket;
	}

	auto get_socket()
	{
		return base_socket;
	}

	auto get_timestamp()const
	{
		return timestamp;
	}

	void set_sequence(ulong seque)
	{
		seque_num = seque;
	}

	auto get_sequence()const
	{
		return seque_num;
	}

	auto get_timeout()const
	{
		return time_out;
	}

	void set_status(RESPONSE_STATUS status)
	{
		response_status = status;
	}

	auto get_status()const
	{
		return response_status;
	}

	auto get_nonblock()const
	{
		return nonblock;
	}

	void set_nonblock(bool is_nonblock)
	{
		nonblock = is_nonblock;
	}


	void add_func_arg_template(func_arg_template tpl)
	{
		func_arg_list[arg_num++] = tpl;
	}

	void semaphore_wait()
	{
		nonblock = false;
		semaphore.wait();
	}

	void semaphore_release()
	{
		semaphore.notify();
	}

private:
	int arg_num;

	RESPONSE_STATUS response_status;

	func_arg_template[int] func_arg_list;
	string func_name;
	rpc_socket_base_interface base_socket;
	Semaphore semaphore;

	bool nonblock;

	ulong timestamp;
	ulong time_out;
	ulong seque_num;
}