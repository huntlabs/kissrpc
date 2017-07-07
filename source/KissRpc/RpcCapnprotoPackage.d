module KissRpc.RpcCapnprotoPackage;

import KissRpc.RpcCapnprotoPayload;
import KissRpc.RpcRequest;
import KissRpc.RpcResponse;
import KissRpc.Logs;

import capnproto.FileDescriptor;
import capnproto.MessageBuilder;
import capnproto.MessageReader;
import capnproto.SerializePacked;
import capnproto.StructList;
import capnproto.Void;
import capnproto.ReaderOptions;
import capnproto.Text;

import java.nio.ByteBuffer;
import KissRpc.RpcPackageBase;
import KissRpc.RpcSocketBaseInterface;


class RpcCapnprotoPackage:RpcPackageBase
{
	this(RpcRequest req)
	{
	 	message = new MessageBuilder();
		this.req = req;

		auto capnprotoPayload = message.initRoot!(Payload);
		capnprotoPayload.setCallInterface(req.getCallFuncName());
		
		auto capnprotoFuncArgList = capnprotoPayload.initArgs(req.getArgsNum());
		
		foreach(k, v; req.getFunArgList())
		{
			auto funcArg = v;
			auto capnprotoFuncArg = capnprotoFuncArgList.get(k);

			capnprotoFuncArg.setType(this.toCapnprotoType(v.getTypeString()));
			capnprotoFuncArg.setPayload(cast(string) v.toBytes());
		}
	}

	this(RpcSocketBaseInterface socket, ubyte[] stream)
	{
		auto byteBuffer = new ByteBuffer[1];
		byteBuffer[0] = ByteBuffer(stream);

		this(socket, byteBuffer);
	}


	this(RpcSocketBaseInterface socket, ByteBuffer[] byteBuffer)
	{
		req = new RpcRequest(socket);

		auto message = new MessageReader(byteBuffer, cast(ReaderOptions)ReaderOptions.DEFAULT_READER_OPTIONS);
		auto capnprotoPayload = message.getRoot!(Payload);

		req.bindFunc(capnprotoPayload.getCallInterface());

		auto funcArgs = capnprotoPayload.getArgs();
	
		foreach(funcArg; funcArgs)
		{
			auto  tlp = this.fromCapnprotoTypeInstanceTemplate(funcArg.getType(),cast(ubyte[]) funcArg.getPayload());
			req.addFuncArgTemplate(tlp);
		}
	}

	RpcRequest getRequestData()
	{
		return req;
	}

	RpcResponse getResponseData()
	{
		return req;
	}

	MessageBuilder getMessageBuilder()
	{
		return message;
	}

	ubyte[] toBinaryStream()
	{
		auto buffer = message.getSegmentsForOutput()[0];
		return buffer.opSlice(0, buffer.slice().capacity());
	}


protected:
	.ArgsType.Type toCapnprotoType( string typeName)const
	{

		switch(typeName)
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
			case "immutable(char)[]": return .ArgsType.Type.tString;
			case "array": return .ArgsType.Type.tArray;

			default: return .ArgsType.Type._NOT_IN_SCHEMA;
		}
	}

	FuncArgTemplate fromCapnprotoTypeInstanceTemplate(.ArgsType.Type type, const ubyte[] data)
	{
		auto arg_tlp = new FuncArgTemplate();

		switch(type)
		{
			case .ArgsType.Type.tBool : arg_tlp.fromBytes!(bool)(data);	break;
			case .ArgsType.Type.tByte : arg_tlp.fromBytes!(byte)(data);	break;
			case .ArgsType.Type.tShort: arg_tlp.fromBytes!(short)(data);	break;
			case .ArgsType.Type.tInt  : arg_tlp.fromBytes!(int)(data);		break;
			case .ArgsType.Type.tLong : arg_tlp.fromBytes!(long)(data);	break;
			case .ArgsType.Type.tUbyte: arg_tlp.fromBytes!(ubyte)(data);	break;
			case .ArgsType.Type.tUshort: arg_tlp.fromBytes!(ushort)(data);	break;
			case .ArgsType.Type.tUint  : arg_tlp.fromBytes!(uint)(data);	break;
			case .ArgsType.Type.tUlong : arg_tlp.fromBytes!(ulong)(data);	break;
			case .ArgsType.Type.tFloat : arg_tlp.fromBytes!(float)(data);	break;
			case .ArgsType.Type.tDouble: arg_tlp.fromBytes!(double)(data);	break;
			case .ArgsType.Type.tReal  : arg_tlp.fromBytes!(real)(data);	break;
			case .ArgsType.Type.tChar  : arg_tlp.fromBytes!(char)(data);	break;
			case .ArgsType.Type.tWchar : arg_tlp.fromBytes!(wchar)(data);	break;
			case .ArgsType.Type.tDchar : arg_tlp.fromBytes!(dchar)(data);	break;
			case .ArgsType.Type.tString : arg_tlp.fromBytes!(immutable(char)[])(data); break;
			case .ArgsType.Type.tArray : arg_tlp.fromBytes!(ushort)(data); break;

			default:
				throw new Exception("instance template is failed! type:");
		}

		return arg_tlp;
	}


private:
	MessageBuilder message;
	RpcRequest req;
}

unittest{

	import std.stdio;
	import std.typetuple;

	struct test_a
	{
		int i=1;
		int j=2;
		long f=3;
		long d=4;
		string s = "test_a";
		int[] d_list;
		
		TypeTuple!(int,int,long,long,string, int[]) memberList;
		
		
		void createTypeTulple()
		{
			memberList[0] = i;
			memberList[1] = j;
			memberList[2] = f;
			memberList[3] = d;
			memberList[4] = s;
			memberList[5] = d_list;
		}
		
		
		void restoreTypeTunlp()
		{
			i = memberList[0];
			j = memberList[1];
			f = memberList[2];
			d = memberList[3];
			s = memberList[4];
			d_list = memberList[5];
		}
	}
	
	struct test
	{
		int i=1;
		int j=2;
		long f=3;
		long d=4;
		string s = "test";
		test_a[] a_test;
		long[] l_list;
		TypeTuple!(int, int, long, long, string, test_a[], long[]) memberList;
		
		
		void createTypeTulple()
		{
			memberList[0] = i;
			memberList[1] = j;
			memberList[2] = f;
			memberList[3] = d;
			memberList[4] = s;
			memberList[5] = a_test;
			memberList[6] = l_list;
		}
		
		void restoreTypeTunlp()
		{
			i = memberList[0];
			j = memberList[1];
			f = memberList[2];
			d = memberList[3];
			s = memberList[4];
			a_test = memberList[5];
			l_list = memberList[6];
		}
		
	}


	test t;
	t.i = 100;
	t.f =1233;
	t.s = "$$$$$$$$$$$$";
	t.a_test = new test_a[6];
	t.l_list = new long[6];
	t.a_test[0].d_list = new int[6];

	t.a_test[0].d_list[0] = 888888;

	t.a_test[0].s = "**************************";
	
	t.l_list[0] = 123456781;
	t.l_list[1] = 9876543321;
	



	RpcRequest req = new RpcRequest;

	req.push(t);
	req.bindFunc("rpc_message_pack");

	auto sendPack = new RpcCapnprotoPackage(req);
	auto send_byte_buf = sendPack.getMessageBuilder().getSegmentsForOutput();

	auto sendStream = new ubyte[send_byte_buf[0].slice().capacity];

	send_byte_buf[0].get(sendStream, 0, sendStream.length);

	writeln("------------------------send rpc capnproto packge--------------------------------");
	writefln("send message, length:%s stream:%s", sendStream.length, sendStream);


	auto recv_pack = new RpcCapnprotoPackage(null, send_byte_buf);
	req = recv_pack.getRequestData;

	test b;

	req.pop(b);

	writeln("------------------------recv rpc capnproto packge--------------------------------");
	writefln("recv message packge, call func:%s, values:%s, %s, %s, %s, %s", req.getCallFuncName(), 
		b.i, b.s, b.l_list[0], b.a_test[0].s, b.a_test[0].d_list[0]);
}
