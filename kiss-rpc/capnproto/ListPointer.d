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

module capnproto.ListPointer;

import java.nio.ByteBuffer;

import capnproto.ElementSize;
import capnproto.WirePointer;

struct ListPointer
{
	static byte elementSize(long ref_)
	{
		return cast(byte)(WirePointer.upper32Bits(ref_) & 7);
	}
	
	static int elementCount(long ref_)
	{
		return WirePointer.upper32Bits(ref_) >>> 3;
	}
	
	static int inlineCompositeWordCount(long ref_)
	{
		return elementCount(ref_);
	}
	
	static void set(ref ByteBuffer buffer, int offset, byte elementSize, int elementCount)
	{
		//TODO: Length assertion.
		buffer.put!int(8 * offset + 4, (elementCount << 3) | elementSize);
	}
	
	static void setInlineComposite(ref ByteBuffer buffer, int offset, int wordCount)
	{
		//TODO: Length assertion.
		buffer.put!int(8 * offset + 4, (wordCount << 3) | ElementSize.INLINE_COMPOSITE);
	}
}
