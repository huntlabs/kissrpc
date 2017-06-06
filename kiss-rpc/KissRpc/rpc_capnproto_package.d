module KissRpc.rpc_capnproto_package;

import KissRpc.rpc_capnproto_payload;
import KissRpc.rpc_request;
import KissRpc.rpc_response;

import capnproto.FileDescriptor;
import capnproto.MessageBuilder;
import capnproto.MessageReader;
import capnproto.SerializePacked;
import capnproto.StructList;
import capnproto.Void;
import capnproto.ReaderOptions;
import capnproto.Text;

import java.nio.ByteBuffer;
import KissRpc.rpc_package_base;
import KissRpc.rpc_socket_base_interface;


class rpc_capnproto_package:rpc_package_base
{
	this(rpc_request req)
	{
	 	message = new MessageBuilder();
		this.req = req;

		auto capnproto_payload = message.initRoot!(Payload);
		capnproto_payload.setCallInterface(req.get_call_func_name());
		
		auto capnproto_func_arg_list = capnproto_payload.initArgs(req.get_args_num());
		
		foreach(k, v; req.get_fun_arg_list())
		{
			auto func_arg = v;
			auto capnproto_func_arg = capnproto_func_arg_list.get(k);

			capnproto_func_arg.setType(this.to_capnproto_type(v.get_type_string()));
			capnproto_func_arg.setPayload(cast(string) v.to_bytes());
		}
	}

	this(rpc_socket_base_interface socket, ubyte[] stream)
	{
		auto byte_buffer = new ByteBuffer[1];
		byte_buffer[0] = ByteBuffer(stream);

		this(socket, byte_buffer);
	}


	this(rpc_socket_base_interface socket, ByteBuffer[] byte_buffer)
	{
		req = new rpc_request(socket);

		auto message = new MessageReader(byte_buffer, cast(ReaderOptions)ReaderOptions.DEFAULT_READER_OPTIONS);
		auto capnproto_payload = message.getRoot!(Payload);

		req.bind_func(capnproto_payload.getCallInterface());

		auto func_args = capnproto_payload.getArgs();
	
		foreach(func_arg; func_args)
		{
			auto  tlp = this.from_capnproto_type_instance_template(func_arg.getType(),cast(ubyte[]) func_arg.getPayload());
			req.add_func_arg_template(tlp);
		}
	}

	rpc_request get_request_data()
	{
		return req;
	}

	rpc_response get_response_data()
	{
		return req;
	}

	MessageBuilder get_message_builder()
	{
		return message;
	}

	ubyte[] to_binary_stream()
	{
		auto buffer = message.getSegmentsForOutput()[0];
		return buffer.opSlice(0, buffer.slice().capacity());
	}


protected:
	.ArgsType.Type to_capnproto_type( string type_name)const
	{

		switch(type_name)
		{
			case "int": return .ArgsType.Type.tInt;
			case "bool": return .ArgsType.Type.tBool;
			case "byte": return .ArgsType.Type.tByte;
			case "short": return .ArgsType.Type.tShort;
			case "void": return .ArgsType.Type.tVoid;
			case "long": return .ArgsType.Type.tLong;
			case "ubyte": return .ArgsType.Type.tUbyte;
			case "ushort": return .ArgsType.Type.tUshort;
			case "uint" : return .ArgsType.Type.tUint;
			case "ulong": return .ArgsType.Type.tUlong;
			case "float": return .ArgsType.Type.tFloat;
			case "double": return .ArgsType.Type.tDouble;
			case "real": return .ArgsType.Type.tReal;
			case "char": return .ArgsType.Type.tChar;
			case "wchar": return .ArgsType.Type.tWchar;
			case "dchar": return .ArgsType.Type.tDchar;
			case "immutable(char)[]": return .ArgsType.Type.string;
			default: return .ArgsType.Type._NOT_IN_SCHEMA;
		}
	}

	func_arg_template from_capnproto_type_instance_template(.ArgsType.Type type, const ubyte[] data)
	{
		auto arg_tlp = new func_arg_template();

		switch(type)
		{
			case .ArgsType.Type.tBool : arg_tlp.from_bytes!(bool)(data);	break;
			case .ArgsType.Type.tByte : arg_tlp.from_bytes!(byte)(data);	break;
			case .ArgsType.Type.tShort: arg_tlp.from_bytes!(short)(data);	break;
			case .ArgsType.Type.tInt  : arg_tlp.from_bytes!(int)(data);		break;
			case .ArgsType.Type.tLong : arg_tlp.from_bytes!(long)(data);	break;
			case .ArgsType.Type.tUbyte: arg_tlp.from_bytes!(ubyte)(data);	break;
			case .ArgsType.Type.tUshort: arg_tlp.from_bytes!(ushort)(data);	break;
			case .ArgsType.Type.tUint  : arg_tlp.from_bytes!(uint)(data);	break;
			case .ArgsType.Type.tUlong : arg_tlp.from_bytes!(ulong)(data);	break;
			case .ArgsType.Type.tFloat : arg_tlp.from_bytes!(float)(data);	break;
			case .ArgsType.Type.tDouble: arg_tlp.from_bytes!(double)(data);	break;
			case .ArgsType.Type.tReal  : arg_tlp.from_bytes!(real)(data);	break;
			case .ArgsType.Type.tChar  : arg_tlp.from_bytes!(char)(data);	break;
			case .ArgsType.Type.tWchar : arg_tlp.from_bytes!(wchar)(data);	break;
			case .ArgsType.Type.tDchar : arg_tlp.from_bytes!(dchar)(data);	break;
			case .ArgsType.Type.string : arg_tlp.from_bytes!(immutable(char)[])(data); break; 

			default: 
				throw new Exception("instance template is failed! type:");
		}

		return arg_tlp;
	}


private:
	MessageBuilder message;
	rpc_request req;
}

unittest{

	import std.stdio;

	auto req = new rpc_request;
	req.push("test message builder", 1, 0.1, 't');
	req.bind_func("rpc_message_pack");

	auto send_pack = new rpc_capnproto_package(req);
	auto send_byte_buf = send_pack.get_message_builder().getSegmentsForOutput();

	auto send_stream = new ubyte[send_byte_buf[0].slice().capacity];

	send_byte_buf[0].get(send_stream, 0, send_stream.length);

	writeln("------------------------send rpc capnproto packge--------------------------------");
	writeln("send message packge stream :", send_stream);


	auto recv_pack = new rpc_capnproto_package(send_byte_buf);
	req = recv_pack.get_request_data;

	string req_arg1;
	int req_arg2;
	double req_arg3;
	char req_arg4;

	req.pop(req_arg1, req_arg2, req_arg3, req_arg4);

	writeln("------------------------recv rpc capnproto packge--------------------------------");
	writefln("recv message packge, call func:%s(%s, %s, %s, %s)", req.get_call_func_name(), 
		req_arg1, req_arg2, req_arg3, req_arg4);
}