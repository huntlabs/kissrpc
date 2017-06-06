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

module capnproto.GeneratedClassSupport;

import java.nio.ByteBuffer;

import capnproto.AnyPointer;
import capnproto.Data;
import capnproto.ReaderArena;
import capnproto.SegmentReader;
import capnproto.Text;

struct GeneratedClassSupport
{
	static SegmentReader decodeRawBytes(ubyte[] s)
	{
		ByteBuffer[] bb;
		return SegmentReader(ByteBuffer(s), new ReaderArena(bb, 0x7fffffffffffffffL));
	}
	
	struct Const(T)
	{
	public:
		this(SegmentReader* reader, int offset, int size)
		{
			this.reader = reader;
			this.offset = offset;
			this.size = size;
		}
		
		T.Reader get() const
		{
			static if(is(T : Data))
				return Data.Reader(cast(ByteBuffer)reader.buffer, offset, size);
			else static if(is(T : Text))
				return Text.Reader(cast(ByteBuffer)reader.buffer, offset, size);
			else
				return AnyPointer.Reader(reader, offset, size).getAs!T();
		}
	
	private:
		SegmentReader* reader;
		int offset;
		int size;
	}
}
