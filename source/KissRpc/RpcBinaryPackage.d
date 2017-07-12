module KissRpc.RpcBinaryPackage;

import KissRpc.Endian;
import KissRpc.Unit;
import KissRpc.Logs;

import util.snappy;

import std.stdio;


enum RPC_PACKAGE_PROTOCOL
{
	TPP_JSON,
	TPP_XML,
	TPP_PROTO_BUF,
	TPP_FLAT_BUF,
	TPP_CAPNP_BUF,
}


enum RPC_PACKAGE_STATUS_CODE
{
	RPSC_OK,
	RPSC_FAILED,
}


class RpcBinaryPackage
{
	this(RPC_PACKAGE_PROTOCOL tpp, ulong msgId = 0, RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, bool isNonblock = true)
	{
		magic = RPC_HANDER_MAGIC;
		ver = RPC_HANDER_VERSION;
		sequenceId = msgId;
		nonblock = isNonblock;

		st = cast(short)tpp;

		st|=(compressType<<8);


		statusCode = cast(short)RPC_PACKAGE_STATUS_CODE.RPSC_OK;

		handerSize = ver.sizeof + st.sizeof + nb.sizeof + ow.sizeof + rp.sizeof + nonblock.sizeof + statusCode.sizeof 
			+ reserved.sizeof + sequenceId.sizeof + bodySize.sizeof;					
	}

	int getStartHanderLength()const
	{
		return magic.sizeof + handerSize.sizeof;
	}

	int getHanderSize()const
	{
		return handerSize + this.getStartHanderLength();
	}

	ulong getPackgeSize()const
	{
		return handerSize + bodySize + this.getStartHanderLength();
	}


	ubyte[] getPayload()
	{
		return bodyPayload;
	}

	short getVersion()const
	{
		return ver;
	}

	short getSerializedType()const
	{
		return st&0x00ff;
	}

	ulong getSequenceId()const
	{
		return sequenceId;
	}

	bool getNonblock()const
	{
		return cast(bool)nonblock;
	}

	short getStatusCode()const
	{
		return statusCode;
	}

	void setStatusCode(const RPC_PACKAGE_STATUS_CODE code)
	{
		statusCode = cast(short)code;
	}

	ulong getBodySize()const
	{
		return bodySize;
	}

	ubyte[] toStream(ubyte[] payload)
	{
		switch(this.getCompressType())
		{
			case RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS:
				payload =cast(ubyte[]) Snappy.compress(cast(byte[])payload);
				break;
				
			case RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC:
				if(payload.length >= RPC_PACKAGE_COMPRESS_DYNAMIC_VALUE)
				{
					payload = cast(ubyte[]) Snappy.compress(cast(byte[])payload);

				}else
				{
					st&=0x00ff;
				}
				break;
				
			default:break;
		}

		bodySize = payload.length;
		
		auto stream = new ubyte[this.getPackgeSize()];
		
		ulong pos = 0;


		pos = writeBytesPos(stream, magic,  pos);
		pos = writeBinaryPos(stream, handerSize, pos);
		pos = writeBinaryPos(stream, ver, pos);
		pos = writeBinaryPos(stream, st, pos);
		pos = writeBinaryPos(stream, nb, pos);
		pos = writeBinaryPos(stream, ow, pos);
		pos = writeBinaryPos(stream, rp, pos);
		pos = writeBinaryPos(stream, nonblock, pos);
		pos = writeBinaryPos(stream, statusCode, pos);
		pos = writeBytesPos(stream, reserved, pos);
		pos = writeBinaryPos(stream, sequenceId, pos);
		pos = writeBinaryPos(stream, bodySize, pos);
		pos = writeBytesPos(stream, payload, pos);

		return stream;
	}

	bool fromStream(ubyte[] data)
	{
		ulong pos = 0;

		try{
			pos = readBytesPos(data, magic, pos);
			pos = readBinaryPos(data, handerSize, pos);
			pos = readBinaryPos(data, ver, pos);
			pos = readBinaryPos(data, st, pos);
			pos = readBinaryPos(data, nb, pos);
			pos = readBinaryPos(data, ow, pos);
			pos = readBinaryPos(data, rp, pos);
			pos = readBinaryPos(data, nonblock, pos);
			pos = readBinaryPos(data, statusCode, pos);
			pos = readBytesPos(data, reserved, pos);
			pos = readBinaryPos(data, sequenceId, pos);
			pos = readBinaryPos(data, bodySize, pos);
			
			bodyPayload = data[pos .. $];


			switch(this.getCompressType())
			{
				case RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS, RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC:
					bodyPayload =cast(ubyte[]) Snappy.uncompress(cast(byte[])bodyPayload);
					bodySize = bodyPayload.length;
					break;
					
				default:break;
			}

					
		}catch(Exception e)
		{
			logWarning("decode binary stream is error:%s", e.msg);
			return false;
		}

		return true;
	}

	bool fromStreamForHander(ubyte[] data)
	{
		ulong pos = 0;
		
		try{

			pos = readBytesPos(data, magic, pos);
			pos = readBinaryPos(data, handerSize, pos);
			pos = readBinaryPos(data, ver, pos);
			pos = readBinaryPos(data, st, pos);
			pos = readBinaryPos(data, nb, pos);
			pos = readBinaryPos(data, ow, pos);
			pos = readBinaryPos(data, rp, pos);
			pos = readBinaryPos(data, nonblock, pos);
			pos = readBinaryPos(data, statusCode, pos);
			pos = readBytesPos(data, reserved, pos);
			pos = readBinaryPos(data, sequenceId, pos);
			pos = readBinaryPos(data, bodySize, pos);

			
		}catch(Exception e)
		{
			logWarning("decode binary stream for hander is error:%s", e.msg);
			return false;
		}

		return this.checkHanderValid();
	}

	bool fromStreamForPayload(ubyte[] data)
	{
		try{

			bodyPayload = data[0 .. $];
				
			switch(this.getCompressType())
			{
				case RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS, RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC:
					bodyPayload =cast(ubyte[]) Snappy.uncompress(cast(byte[])bodyPayload);
					bodySize = bodyPayload.length;
					break;
					
				default:break;
			}


		}catch(Exception e)
		{
			logWarning("decode body stream is error:%s", e.msg);
			return false;
		}

		return true;
	}


	bool checkHanderValid()
	{
		return magic == RPC_HANDER_MAGIC && ver == RPC_HANDER_VERSION && this.getPackgeSize <= RPC_PACKAGE_MAX;
	}

	RPC_PACKAGE_COMPRESS_TYPE getCompressType()
	{
		return cast(RPC_PACKAGE_COMPRESS_TYPE)((st & 0xff00)>>8);
	}

protected:

	ulong writeBinaryPos(T)(ubyte[] data, T t, ulong pos)
	{
		T bits= hostToNet(t);
		data[pos .. pos + t.sizeof ] = (cast(ubyte*)&bits)[0 .. t.sizeof];
		return pos + t.sizeof;
	}

	ulong writeBytesPos(ubyte[] data, ubyte[] bytes, ulong pos)
	{
		data[pos .. pos + bytes.length] = bytes[0 .. bytes.length];
		return pos + bytes.length;
	}

	ulong readBinaryPos(T)(ubyte[] data, ref T t, ulong pos)
	{
		IntBuf!(T) bits;
		bits.bytes = data[pos .. pos + t.sizeof];
		t = netToHost(bits.value);
	
		return pos + t.sizeof;
	}

	ulong readBytesPos(ubyte[] data, ubyte[] bytes, ulong pos)
	{
		bytes[0 .. $] = data[pos .. pos + bytes.length];

		return pos + bytes.length;
	}


private:
	ubyte[8] magic;

	short handerSize;
	short ver;
	short st;
	short nb;
	short ow;
	short rp;
	short nonblock;
	short statusCode;

	ubyte[8] reserved;
	ulong sequenceId;
	ulong bodySize;

	ubyte[] bodyPayload;
}


unittest{
	import std.stdio;

	auto send_pkg  = new RpcBinaryPackage(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, 0, RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC);
	auto send_data = "aaaaaaaabbbbbbbbbbbbbbcccccccccccccccdddddddddddddddddddd";

	writeln("-----------------------------------------------------");

	auto snd_stream = send_pkg.toStream(cast(ubyte[])send_data);

	writefln("send stream, length:%s, compress:%s, data:%s", snd_stream.length, send_pkg.getCompressType, snd_stream);

	auto recvPkg = new RpcBinaryPackage(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF);

	recvPkg.fromStream(snd_stream);

	writeln("----------------------------------------------------");

	writefln("recv stream, length:%s, compress:%s, data:%s", recvPkg.getPackgeSize(), recvPkg.getCompressType, recvPkg.getPayload());

}
