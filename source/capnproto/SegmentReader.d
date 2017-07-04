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

module capnproto.SegmentReader;

import java.nio.ByteBuffer;

import capnproto.Arena;
import capnproto.Constants;

struct SegmentReader
{
public: //Variables.
	static immutable SegmentReader EMPTY = cast(immutable SegmentReader)SegmentReader(ByteBuffer(new ubyte[](8)), null);
	
	ByteBuffer buffer;

public: //Methods.
	this(ByteBuffer buffer, Arena arena)
	{
		this.buffer = buffer;
		this.arena = arena;
	}
	
	long get(size_t index) const
	{
		return buffer.get!long(index * Constants.BYTES_PER_WORD);
	}

package: //Variables.
	Arena arena;
}

union FloatIntBits
{
	int intBits;
	float floatBits;
}

float intBitsToFloat(int x)
{
	FloatIntBits bits;
	bits.intBits = x;
	return bits.floatBits;
}

int floatToIntBits(float x)
{
	FloatIntBits bits;
	bits.floatBits = x;
	return bits.intBits;
}

union DoubleLongBits
{
	long intBits;
	double floatBits;
}

double longBitsToDouble(long x)
{
	DoubleLongBits bits;
	bits.intBits = x;
	return bits.floatBits;
}

long doubleToLongBits(double x)
{
	DoubleLongBits bits;
	bits.floatBits = x;
	return bits.intBits;
}
