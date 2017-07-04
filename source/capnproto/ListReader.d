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

module capnproto.ListReader;

import java.nio.ByteBuffer;

import capnproto.Constants;
import capnproto.Data;
import capnproto.ElementSize;
import capnproto.SegmentReader;
import capnproto.StructReader;
import capnproto.Text;
import capnproto.WireHelpers;

struct ListReader
{
public: //Methods.
	this(SegmentReader* segment, int ptr, int elementCount, int step, int structDataSize, short structPointerCount, int nestingLimit)
	{
		this.segment = segment;
		this.ptr = ptr;
		this.elementCount = elementCount;
		this.step = step;
		this.structDataSize = structDataSize;
		this.structPointerCount = structPointerCount;
		this.nestingLimit = nestingLimit;
	}
	
	size_t length() const
	{
		return this.elementCount;
	}
	
	bool _getBooleanElement(size_t index)
	{
		long bindex = cast(long)index * this.step;
		byte b = this.segment.buffer.get!byte(this.ptr + cast(int)(bindex / Constants.BITS_PER_BYTE));
		return (b & (1 << (bindex % 8))) != 0;
	}
	
	byte _getByteElement(size_t index)
	{
		return this.segment.buffer.get!byte(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE));
	}
	
	short _getShortElement(size_t index)
	{
		return this.segment.buffer.get!short(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE));
	}
	
	int _getIntElement(size_t index)
	{
		return this.segment.buffer.get!int(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE));
	}
	
	long _getLongElement(size_t index)
	{
		return this.segment.buffer.get!long(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE));
	}
	
	float _getFloatElement(size_t index)
	{
		return this.segment.buffer.get!float(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE));
	}
	
	double _getDoubleElement(size_t index)
	{
		return this.segment.buffer.get!double(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE));
	}
	
	T.Reader _getStructElement(T)(size_t index)
	{
		//TODO: Check nesting limit.
		long indexBit = cast(long)index * this.step;
		int structData = this.ptr + cast(int)(indexBit / Constants.BITS_PER_BYTE);
		int structPointers = structData + (this.structDataSize / Constants.BITS_PER_BYTE);
		return T.Reader(this.segment, structData, structPointers / 8, this.structDataSize, this.structPointerCount, this.nestingLimit - 1);
	}
	
	T.Reader _getPointerElement(T)(size_t index)
	{
		import std.string : startsWith;
		import std.traits;
		alias name = fullyQualifiedName!T;
		
		int pointer = (this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD;
		static if(is(T : Data))
			return WireHelpers.readDataPointer(segment, pointer, null, 0, 0);
		else static if(is(T : Text))
			return WireHelpers.readTextPointer(segment, pointer, null, 0, 0);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.readListPointer!(T.Reader)(this.segment, pointer, null, 0, T.elementSize, this.nestingLimit);
		else
			return WireHelpers.readStructPointer!(T.Reader)(this.segment, pointer, null, 0, ElementSize.INLINE_COMPOSITE, this.nestingLimit);
	}
	
	T.Reader _getPointerElement(T)(size_t index, ref ByteBuffer defaultBuffer, int defaultOffset, int defaultSize)
	{
		static if(is(T : Data))
			return WireHelpers.readDataPointer(this.segment, (this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD, defaultBuffer, defaultOffset, defaultSize);
		static if(is(T : Text))
			return WireHelpers.readTextPointer(this.segment, (this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD, defaultBuffer, defaultOffset, defaultSize);
		else
			return WireHelpers.readDataPointer(this.segment, (this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD, defaultBuffer, defaultOffset, defaultSize);
	}

package:
	SegmentReader* segment;
	int ptr; //Byte offset to front of list.
	int elementCount;
	int step; //In bits.
	int structDataSize; //In bits.
	short structPointerCount;
	int nestingLimit;
}
