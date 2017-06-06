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

module capnproto.StructPointer;

import java.nio.ByteBuffer;

import capnproto.StructSize;
import capnproto.WirePointer;

struct StructPointer
{
	static short dataSize(long ref_)
	{
		//In words.
		return cast(short)(WirePointer.upper32Bits(ref_) & 0xffff);
	}
	
	static short ptrCount(long ref_)
	{
		return cast(short)(WirePointer.upper32Bits(ref_) >>> 16);
	}
	
	static int wordSize(long ref_)
	{
		return cast(int)dataSize(ref_) + cast(int)ptrCount(ref_);
	}
	
	static void setFromStructSize(ref ByteBuffer buffer, int offset, immutable(StructSize) size)
	{
		buffer.put!short(8 * offset + 4, size.data);
		buffer.put!short(8 * offset + 6, size.pointers);
	}
	
	static void set(ref ByteBuffer buffer, int offset, short dataSize, short pointerCount)
	{
		buffer.put!short(8 * offset + 4, dataSize);
		buffer.put!short(8 * offset + 6, pointerCount);
	}
}
