module KissRpc.rpc_binary_package;

import KissRpc.endian;
import KissRpc.unit;
import KissRpc.logs;

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


class rpc_binary_package
{
	this(RPC_PACKAGE_PROTOCOL tpp, ulong msg_id, bool is_nonblock = true)
	{
		magic = RPC_HANDER_MAGIC;
		ver = RPC_HANDER_VERSION;
		sequence_id = msg_id;
		nonblock = is_nonblock;

		st = cast(short)tpp;
		status_code = cast(short)RPC_PACKAGE_STATUS_CODE.RPSC_OK;

		hander_size = ver.sizeof + st.sizeof + nb.sizeof + ow.sizeof + rp.sizeof + nonblock.sizeof + status_code.sizeof 
			+ reserved.sizeof + sequence_id.sizeof + body_size.sizeof;					
	}

	int get_start_hander_lenth()const
	{
		return magic.sizeof + hander_size.sizeof;
	}

	int get_hander_size()const
	{
		return hander_size + this.get_start_hander_lenth();
	}

	ulong get_packge_size()const
	{
		return hander_size + body_size + this.get_start_hander_lenth();
	}


	ubyte[] get_payload()
	{
		return body_payload;
	}

	short get_version()const
	{
		return ver;
	}

	short get_serialized_type()const
	{
		return st;
	}

	ulong get_sequence_id()const
	{
		return sequence_id;
	}

	bool get_nonblock()const
	{
		return cast(bool)nonblock;
	}

	short get_status_code()const
	{
		return status_code;
	}

	void set_status_code(const RPC_PACKAGE_STATUS_CODE code)
	{
		status_code = cast(short)code;
	}

	ulong get_body_size()const
	{
		return body_size;
	}

	ubyte[] to_stream(ubyte[] payload)
	{
		body_size = payload.length;

		auto stream = new ubyte[this.get_packge_size()];

		ulong pos = 0;

		pos = write_bytes_pos(stream, magic,  pos);
		pos = write_binary_pos(stream, hander_size, pos);
		pos = write_binary_pos(stream, ver, pos);
		pos = write_binary_pos(stream, st, pos);
		pos = write_binary_pos(stream, nb, pos);
		pos = write_binary_pos(stream, ow, pos);
		pos = write_binary_pos(stream, rp, pos);
		pos = write_binary_pos(stream, nonblock, pos);
		pos = write_binary_pos(stream, status_code, pos);
		pos = write_bytes_pos(stream, reserved, pos);
		pos = write_binary_pos(stream, sequence_id, pos);
		pos = write_binary_pos(stream, body_size, pos);
		pos = write_bytes_pos(stream, payload, pos);

		return stream;
	}

	bool from_stream(ubyte[] data)
	{
		ulong pos = 0;

		try{
			pos = read_bytes_pos(data, magic, pos);
			pos = read_binary_pos(data, hander_size, pos);
			pos = read_binary_pos(data, ver, pos);
			pos = read_binary_pos(data, st, pos);
			pos = read_binary_pos(data, nb, pos);
			pos = read_binary_pos(data, ow, pos);
			pos = read_binary_pos(data, rp, pos);
			pos = read_binary_pos(data, nonblock, pos);
			pos = read_binary_pos(data, status_code, pos);
			pos = read_bytes_pos(data, reserved, pos);
			pos = read_binary_pos(data, sequence_id, pos);
			pos = read_binary_pos(data, body_size, pos);
			
			body_payload = data[pos .. $];
					
		}catch(Exception e)
		{
			log_warning("decode binary stream is error:%s", e.msg);
			return false;
		}

		return true;
	}

	bool from_stream_for_hander(ubyte[] data)
	{
		ulong pos = 0;
		
		try{

			pos = read_bytes_pos(data, magic, pos);
			pos = read_binary_pos(data, hander_size, pos);
			pos = read_binary_pos(data, ver, pos);
			pos = read_binary_pos(data, st, pos);
			pos = read_binary_pos(data, nb, pos);
			pos = read_binary_pos(data, ow, pos);
			pos = read_binary_pos(data, rp, pos);
			pos = read_binary_pos(data, nonblock, pos);
			pos = read_binary_pos(data, status_code, pos);
			pos = read_bytes_pos(data, reserved, pos);
			pos = read_binary_pos(data, sequence_id, pos);
			pos = read_binary_pos(data, body_size, pos);

			
		}catch(Exception e)
		{
			log_warning("decode binary stream for hander is error:%s", e.msg);
			return false;
		}

		return this.check_hander_valid();
	}

	bool from_stream_for_payload(ubyte[] data)
	{
		try{

			body_payload = data[0 .. $];
		
		}catch(Exception e)
		{
			log_warning("decode body stream is error:%s", e.msg);
			return false;
		}

		return true;
	}


	bool check_hander_valid()
	{
		return magic == RPC_HANDER_MAGIC && ver == RPC_HANDER_VERSION && this.get_packge_size <= RPC_PACKAGE_MAX;
	}

protected:

	ulong write_binary_pos(T)(ubyte[] data, T t, ulong pos)
	{
		T bits= hostToNet(t);
		data[pos .. pos + t.sizeof ] = (cast(ubyte*)&bits)[0 .. t.sizeof];
		return pos + t.sizeof;
	}

	ulong write_bytes_pos(ubyte[] data, ubyte[] bytes, ulong pos)
	{
		data[pos .. pos + bytes.length] = bytes[0 .. bytes.length];
		return pos + bytes.length;
	}

	ulong read_binary_pos(T)(ubyte[] data, ref T t, ulong pos)
	{
		IntBuf!(T) bits;
		bits.bytes = data[pos .. pos + t.sizeof];
		t = netToHost(bits.value);
	
		return pos + t.sizeof;
	}

	ulong read_bytes_pos(ubyte[] data, ubyte[] bytes, ulong pos)
	{
		bytes[0 .. $] = data[pos .. pos + bytes.length];

		return pos + bytes.length;
	}


private:
	ubyte[8] magic;

	short hander_size;
	short ver;
	short st;
	short nb;
	short ow;
	short rp;
	short nonblock;
	short status_code;

	ubyte[8] reserved;
	ulong sequence_id;
	ulong body_size;

	ubyte[] body_payload;
}


unittest{
	import std.stdio;

	auto send_pkg  = new rpc_binary_package(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, 0);
	auto send_data = "aaaaaaaabbbbbbbbbbbbbbcccccccccccccccdddddddddddddddddddd";

	de_writefln("-----------------------------------------------------");

	auto snd_stream = send_pkg.to_stream(cast(ubyte[])send_data);

	writefln("send stream:%s, length:%s", snd_stream, send_pkg.get_packge_size());

	auto recv_pkg = new rpc_binary_package(RPC_PACKAGE_PROTOCOL.TPP_CAPNP_BUF, 0);

	recv_pkg.from_stream(snd_stream);

	de_writefln("----------------------------------------------------");

	writefln("recv stream:%s. length:%s", recv_pkg.get_payload(), recv_pkg.get_packge_size());

}
