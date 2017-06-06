module capnproto.MemoryMapped;

import std.mmfile : MmFile;

import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;

final class MemoryMapped : ReadableByteChannel
{
public: //Methods.
	this(MmFile file)
	{
		this.file = file;
	}
	
	bool isOpen()
	{
		return true;
	}
	
	void close()
	{
		
	}
	
	///Setup map from file to dst.
	size_t read(ref ByteBuffer dst)
	{
		import std.algorithm : min;
		auto size = min(dst.remaining(), file.length - index);
		if(size == 0)
			return 0;
		dst.buffer = cast(ubyte[])file[index..index+size];
		dst.position += size;
		index += size;
		return size;
	}

private: //Variables.
	MmFile file;
	size_t index;
}
