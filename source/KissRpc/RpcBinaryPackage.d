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
		sequenceId = cast(uint)msgId;

		statusInfo |= (isNonblock ? RPC_HANDER_NONBLOCK_FLAG : 0);

		st = cast(short)tpp;

		st |= (compressType << 8);

		statusInfo |= (RPC_PACKAGE_STATUS_CODE.RPSC_OK & RPC_HANDER_STATUS_CODE_FLAG);

		handerSize = ver.sizeof + st.sizeof + statusInfo.sizeof + reserved.sizeof + sequenceId.sizeof + bodySize.sizeof;					
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

	ulong getBodySize()const
	{
		return bodySize;
	}

	short getSerializedType()const
	{
		return st & RPC_HANDER_SERI_FLAG;
	}

	ulong getSequenceId()const
	{
		return sequenceId;
	}

	bool getNonblock()const
	{
		return cast(bool)statusInfo & RPC_HANDER_NONBLOCK_FLAG;
	}

	short getStatusCode()const
	{
		return statusInfo & RPC_HANDER_STATUS_CODE_FLAG;
	}

	void setStatusCode(const RPC_PACKAGE_STATUS_CODE code)
	{
		statusInfo |= (code & RPC_HANDER_STATUS_CODE_FLAG);
	}

	bool getHB()const
	{
		return statusInfo & RPC_HANDER_HB_FLAG;
	}

	void setHBPackage()
	{
		statusInfo |= RPC_HANDER_HB_FLAG;
	}

	bool getOW()const
	{
		return cast(bool)statusInfo & RPC_HANDER_OW_FLAG;
	}

	void setOWPackage()
	{
		statusInfo |= RPC_HANDER_OW_FLAG;
	}

	bool getRP()const
	{
		return cast(bool)statusInfo & RPC_HANDER_RP_FLAG;
	}

	void setRP()
	{
		statusInfo |= RPC_HANDER_RP_FLAG;
	}


	ubyte[] toStream(ubyte[] payload)
	{
		switch(this.getCompressType())
		{
			case RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS:
				payload =cast(ubyte[]) Snappy.compress(cast(byte[])payload);
				st |= RPC_HANDER_COMPRESS_FLAG;
				break;
				
			case RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC:
				if(payload.length >= RPC_PACKAGE_COMPRESS_DYNAMIC_VALUE)
				{
					payload = cast(ubyte[]) Snappy.compress(cast(byte[])payload);
					st |= RPC_HANDER_COMPRESS_FLAG;
				}else
				{
					st &= ~RPC_HANDER_COMPRESS_FLAG;
				}
				break;
				
			default:break;
		}

		bodySize = cast(ushort)payload.length;
		
		auto stream = new ubyte[this.getPackgeSize()];
		
		ulong pos = 0;


		pos = writeBytesPos(stream, magic,  pos);
		pos = writeBytePos(stream, handerSize, pos);
		pos = writeBytePos(stream, ver, pos);

		pos = writeBinaryPos(stream, st, pos);

		pos = writeBytePos(stream, statusInfo, pos);
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
			pos = readBytePos(data, handerSize, pos);
			pos = readBytePos(data, ver, pos);

			pos = readBinaryPos(data, st, pos);

			pos = readBytePos(data, statusInfo, pos);
			pos = readBytesPos(data, reserved, pos);

			pos = readBinaryPos(data, sequenceId, pos);
			pos = readBinaryPos(data, bodySize, pos);
			
			bodyPayload = data[pos .. $];

			if(this.isCompress)
			{
				bodyPayload =cast(ubyte[]) Snappy.uncompress(cast(byte[])bodyPayload);
				bodySize = cast(ushort)bodyPayload.length;
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
			pos = readBytePos(data, handerSize, pos);
			pos = readBytePos(data, ver, pos);
			
			pos = readBinaryPos(data, st, pos);
			
			pos = readBytePos(data, statusInfo, pos);
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
				
			if(this.isCompress)
			{
				bodyPayload =cast(ubyte[]) Snappy.uncompress(cast(byte[])bodyPayload);
				bodySize = cast(ushort)bodyPayload.length;
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
		return cast(RPC_PACKAGE_COMPRESS_TYPE)((st & RPC_HANDER_CPNPRESS_TYPE_FLAG)>>8);
	}

	bool isCompress()
	{
		return cast(bool)(st & RPC_HANDER_COMPRESS_FLAG);
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

	ulong writeBytePos(ubyte[] data, ubyte abyte, ulong pos)
	{
		data[pos .. pos + abyte.sizeof] = abyte;
		return pos + abyte.sizeof;
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

	ulong readBytePos(ubyte[] data, ref ubyte abyte, ulong pos)
	{
		abyte = (data[pos .. pos + abyte.sizeof])[0];
		return pos + abyte.sizeof;
	}


private:
	ubyte[2] magic;

	ubyte handerSize;
	ubyte ver;
	short st;

	ubyte statusInfo; // [nb:1bit, ow:1bit, rp:1bit, nonblock:1bit, statusCode:4bit] 

	ubyte[2] reserved;
	uint sequenceId;
	ushort bodySize;

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
