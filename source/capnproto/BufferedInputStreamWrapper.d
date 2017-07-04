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

module capnproto.BufferedInputStreamWrapper;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;

import capnproto.BufferedInputStream;

final class BufferedInputStreamWrapper : BufferedInputStream
{
public: //Methods.
	this(ReadableByteChannel chan)
	{
		this.inner = chan;
		this.buf = ByteBuffer(new ubyte[](8192));
		this.buf.limit = 0;
	}
	
	size_t read(ref ByteBuffer dst)
	{
		auto numBytes = dst.remaining();
		if(numBytes < this.buf.remaining())
		{
			//# Serve from the current buffer.
			auto slice = this.buf.slice();
			slice.limit = numBytes;
			dst.put!ByteBuffer(slice);
			this.buf.position += numBytes;
			return numBytes;
		}
		else
		{
			//# Copy current available into destination.
			auto fromFirstBuffer = this.buf.remaining();
			{
				auto slice = this.buf.slice();
				slice.limit = fromFirstBuffer;
				dst.put!ByteBuffer(slice);
			}
			
			numBytes -= fromFirstBuffer;
			if(numBytes <= this.buf.capacity())
			{
				//# Read the next buffer-full.
				this.buf.clear();
				auto n = readAtLeast(this.inner, this.buf, numBytes);
				
				this.buf.rewind();
				auto slice = this.buf.slice();
				slice.limit = numBytes;
				dst.put!ByteBuffer(slice);
				
				this.buf.limit = n;
				this.buf.position = numBytes;
				return fromFirstBuffer + numBytes;
			}
			else
			{
				//# Forward large read to the underlying stream.
				this.buf.clear();
				this.buf.limit = 0;
				return fromFirstBuffer + readAtLeast(this.inner, dst, numBytes);
			}
		}
	}
	
	ByteBuffer* getReadBuffer()
	{
		if(this.buf.remaining() == 0)
		{
			this.buf.clear();
			auto n = readAtLeast(this.inner, this.buf, 1);
			this.buf.rewind();
			this.buf.limit = n;
		}
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
	
	int readAtLeast(ReadableByteChannel reader, ref ByteBuffer buf, size_t minBytes)
	{
		int numRead = 0;
		while(numRead < minBytes)
		{
			auto res = reader.read(buf);
			if(res < 0)
				throw new Error("premature EOF");
			numRead += res;
		}
		return numRead;
	}

private: //Variables.
	ReadableByteChannel inner;
	ByteBuffer buf;
}
