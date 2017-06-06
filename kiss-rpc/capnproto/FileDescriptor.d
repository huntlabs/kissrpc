module capnproto.FileDescriptor;

import std.stdio : File;

import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;

final class FileDescriptor : ReadableByteChannel, WritableByteChannel
{
public: //Methods.
	this(File file)
	{
		this.file = file;
	}
	
	bool isOpen()
	{
		return true;
	}
	
	void close()
	{
		file.close();
	}
	
	///Reads from fd to dst.
	size_t read(ref ByteBuffer dst)
	{
		if(dst.buffer is null)
			dst.buffer = new ubyte[](dst.remaining);
		file.rawRead(dst.buffer);
		dst.position = dst.buffer.length;
		dst.limit = dst.buffer.length;
		return dst.buffer.length;
	}
	
	///Writes from src to fd.
	size_t write(ref ByteBuffer src)
	{
		file.rawWrite(src.buffer[0..src.limit]);
		src.position = src.limit;
		return src.limit;
	}

private: //Variables.
	File file;
}
