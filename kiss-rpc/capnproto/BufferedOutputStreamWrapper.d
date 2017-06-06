// Copyright (c) 2013-2014 Sandstorm Development Group, Inc. and contributors
// Licensed under the MIT License:
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

module capnproto.BufferedOutputStreamWrapper;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.WritableByteChannel;

import capnproto.BufferedOutputStream;

final class BufferedOutputStreamWrapper : BufferedOutputStream
{
public: //Methods.
	this(WritableByteChannel w)
	{
		this.inner = w;
		this.buf = ByteBuffer(new ubyte[](8192));
	}
	
	size_t write(ref ByteBuffer src)
	{
		auto available = this.buf.remaining();
		auto size = src.remaining();
		if(size <= available)
			this.buf.put!ByteBuffer(src);
		else if(size <= this.buf.capacity())
		{
			//# Too much for this buffer, but not a full buffer's worth,
			//# so we'll go ahead and copy.
			auto slice = src.slice();
			slice.limit = available;
			this.buf.put!ByteBuffer(slice);
			
			this.buf.rewind();
			while(!this.buf.empty())
				this.inner.write(this.buf);
			this.buf.rewind();
			
			src.position += available;
			this.buf.put!ByteBuffer(src);
		}
		else
		{
			//# Writing so much data that we might as well write
			//# directly to avoid a copy.
			auto pos = this.buf.position;
			this.buf.rewind();
			auto slice = this.buf.slice();
			slice.limit = pos;
			while(!slice.empty())
				this.inner.write(slice);
			while(!src.empty())
				this.inner.write(src);
		}
		return size;
	}
	
	ByteBuffer* getWriteBuffer()
	{
		return &this.buf;
	}
	
	void close()
	{
		this.inner.close();
	}
	
	bool isOpen()
	{
		return this.inner.isOpen();
	}
	
	void flush()
	{
		auto pos = this.buf.position;
		this.buf.rewind();
		this.buf.limit = pos;
		this.inner.write(this.buf);
		this.buf.clear();
	}

private: //Variables.
	WritableByteChannel inner;
	ByteBuffer buf;
}
