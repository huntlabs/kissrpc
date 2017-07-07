module java.nio.ByteBuffer;

//TODO: Always little Endian.
struct ByteBuffer
{
public: //Variables.
	ubyte[] buffer;
	size_t position;

public: //Methods.
	this(ubyte[] buffer)
	{
		this.buffer = buffer;
		this.limit_ = buffer.length;
	}
	
	this(ubyte[] buffer, size_t limit_, size_t position)
	{
		this.buffer = buffer;
		this.limit_ = limit_;
		this.position = position;
	}
	
	static ByteBuffer prepare(size_t size)
	{
		return ByteBuffer(null, size, 0);
	}
	
	ByteBuffer slice()
	{
		return ByteBuffer(buffer[position..limit]);
	}
	
	ubyte[] opSlice(size_t i, size_t j)
	{
		return buffer[i..j];
	}
	
	void limit(size_t newLimit)
	{
		limit_ = newLimit;
		if(position > limit_)
			position = limit_;
	}
	
	size_t limit() const
	{
		return limit_;
	}
	
	void rewind()
	{
		position = 0;
	}
	
	bool empty() const
	{
		return remaining == 0;
	}
	
	size_t remaining() const
	{
		if(position >= limit_)
			return 0;
		return limit_ - position;
	}
	
	size_t capacity() const
	{
		return buffer.length;
	}
	
	void clear()
	{
		position = 0;
		limit_ = capacity();
	}
	
	void put(T)(ref T src) if(is(T == ByteBuffer))
	{
		size_t n = src.remaining;
		//if(n > remaining())
		//	throw new Exception("Buffer overflow.");
		buffer[position..position+n] = src.buffer[src.position..src.position+n];
		src.position += n;
		position += n;
	}
	
	void put(T)(T src)
	{
		scope(exit) position += T.sizeof;
		put(position, src);
	}
	
	void put(T)(size_t pos, T src)
	{
		//if(remaining() == 0)
		//	throw new Exception("Buffer overflow.");
		buffer[pos..pos+T.sizeof] = (cast(ubyte*)&src)[0..T.sizeof];
	}
	
	void get(ref ubyte[] dst, size_t offset, size_t length)
	{
		//if(length > remaining())
		//	throw new Exception("Buffer underflow.");
		dst[offset..offset+length] = buffer[position..position+length];
		position += length;
	}
	
	T get(T)()
	{
		scope(exit) position += T.sizeof;
		return get!T(position);
	}
	
	T get(T)(size_t index) const
	{
		return *cast(T*)buffer[index..index+T.sizeof];
	}

private: //Variables.
	size_t limit_;
}
