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

module capnproto.ArrayInputStream;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;

import capnproto.BufferedInputStream;

final class ArrayInputStream : BufferedInputStream
{
public: //Variables.
	ByteBuffer buf;

public: //Methods.
	this(ByteBuffer buf)
	{
		this.buf = buf;
	}
	
	this(ref ubyte[] buf)
	{
		this.buf = ByteBuffer(buf);
	}
	
	size_t read(ref ByteBuffer dst)
	{
		import std.algorithm : min;
		auto size = min(dst.remaining(), this.buf.remaining());
		
		auto slice = this.buf.slice();
		slice.limit = size;
		dst.buffer = slice.buffer;
		dst.position += size;
		this.buf.position += size;
		
		return size;
	}
	
	ByteBuffer* getReadBuffer()
	{
		return &this.buf;
	}
	
	void close()
	{
		return;
	}
	
	bool isOpen()
	{
		return true;
	}
}
