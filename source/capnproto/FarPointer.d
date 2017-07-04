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

module capnproto.FarPointer;

import java.nio.ByteBuffer;

import capnproto.WirePointer;

struct FarPointer
{
	static uint getSegmentId(ulong ref_)
	{
		return WirePointer.upper32Bits(ref_);
	}
	
	static uint positionInSegment(ulong ref_)
	{
		return WirePointer.offsetAndKind(ref_) >>> 3;
	}
	
	static bool isDoubleFar(ulong ref_)
	{
		return ((WirePointer.offsetAndKind(ref_) >>> 2) & 1) != 0;
	}
	
	static void setSegmentId(ref ByteBuffer buffer, int offset, int segmentId)
	{
		buffer.put!int(8 * offset + 4, segmentId);
	}
	
	static void set(ref ByteBuffer buffer, int offset, bool isDoubleFar, int pos)
	{
		int idf = isDoubleFar? 1 : 0;
		WirePointer.setOffsetAndKind(buffer, offset, (pos << 3) | (idf << 2) | WirePointer.FAR);
	}
}
