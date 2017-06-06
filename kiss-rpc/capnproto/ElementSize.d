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

module capnproto.ElementSize;

struct ElementSize
{
	static enum ubyte VOID = 0;
	static enum ubyte BIT = 1;
	static enum ubyte BYTE = 2;
	static enum ubyte TWO_BYTES = 3;
	static enum ubyte FOUR_BYTES = 4;
	static enum ubyte EIGHT_BYTES = 5;
	static enum ubyte POINTER = 6;
	static enum ubyte INLINE_COMPOSITE = 7;
	
	static uint dataBitsPerElement(ubyte size)
	{
		switch(size)
		{
			case VOID:
				return 0;
			case BIT:
				return 1;
			case BYTE:
				return 8;
			case TWO_BYTES:
				return 16;
			case FOUR_BYTES:
				return 32;
			case EIGHT_BYTES:
				return 64;
			case POINTER:
				return 0;
			case INLINE_COMPOSITE:
				return 0;
			default:
				break;
		}
		import std.conv : to;
		assert(0, "Impossible field size: " ~ to!string(size));
	}
	
	static ushort pointersPerElement(ubyte size)
	{
		switch(size)
		{
			case POINTER:
				return 1;
			default:
				break;
		}
		return 0;
	}
}
