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

module capnproto.ListBuilder;

import std.string : startsWith;
import std.traits;

import capnproto.Constants;
import capnproto.Data;
import capnproto.SegmentBuilder;
import capnproto.StructBuilder;
import capnproto.Text;
import capnproto.WireHelpers;

struct ListBuilder
{
public: //Methods.
	this(SegmentBuilder* segment, int ptr, int elementCount, int step, int structDataSize, short structPointerCount)
	{
		this.segment = segment;
		this.ptr = ptr;
		this.elementCount = elementCount;
		this.step = step;
		this.structDataSize = structDataSize;
		this.structPointerCount = structPointerCount;
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
	
	void _setBooleanElement(size_t index, bool value)
	{
		long bitOffset = index * this.step;
		byte bitnum = cast(byte)(bitOffset % 8);
		int position = cast(int)(this.ptr + (bitOffset / 8));
		byte oldValue = this.segment.buffer.get!byte(position);
		this.segment.buffer.put!ubyte(position, cast(byte)((oldValue & (~(1 << bitnum))) | ((value? 1 : 0) << bitnum)));
	}
	
	void _setByteElement(size_t index, byte value)
	{
		this.segment.buffer.put!ubyte(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE), value);
	}
	
	void _setShortElement(size_t index, short value)
	{
		this.segment.buffer.put!short(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE), value);
	}
	
	void _setIntElement(size_t index, int value)
	{
		this.segment.buffer.put!int(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE), value);
	}
	
	void _setLongElement(size_t index, long value)
	{
		this.segment.buffer.put!long(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE), value);
	}
	
	void _setFloatElement(size_t index, float value)
	{
		this.segment.buffer.put!float(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE), value);
	}
	
	void _setDoubleElement(size_t index, double value)
	{
		this.segment.buffer.put!double(this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE), value);
	}
	
	T.Builder _getStructElement(T)(size_t index)
	{
		long indexBit = cast(long)index * this.step;
		int structData = this.ptr + cast(int)(indexBit / Constants.BITS_PER_BYTE);
		int structPointers = (structData + (this.structDataSize / 8)) / 8;
		return T.Builder(this.segment, structData, structPointers, this.structDataSize, this.structPointerCount);
	}
	
	T.Builder _getPointerElement(T)(size_t index)
	{
		alias name = fullyQualifiedName!T;
		
		int pointer = (this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD;
		static if(is(T : Data))
			return WireHelpers.getWritableDataPointer(pointer, segment, null, 0, 0);
		else static if(is(T : Text))
			return WireHelpers.getWritableTextPointer(pointer, segment, null, 0, 0);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.getWritableListPointer!(T.Builder)(pointer, this.segment, T.elementSize, null, 0);
		else static if(name.startsWith("capnproto.StructList"))
			return WireHelpers.getWritableStructListPointer!(T.Builder)(pointer, this.segment, T.structSize, null, 0);
		else
			return WireHelpers.getWritableStructPointer!(T.Builder)(pointer, this.segment, T.structSize, null, 0);
	}
	
	T.Builder _initPointerElement(T)(size_t index, int elementCount)
	{
		alias name = fullyQualifiedName!T;
		static if(name.startsWith("capnproto.StructList"))
			return WireHelpers.initStructListPointer!(T.Builder)((this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD, this.segment, elementCount, T.structSize);
		else
			return WireHelpers.initListPointer!(T.Builder)((this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD, this.segment, elementCount, T.elementSize);
	}
	
	void _setPointerElement(Reader)(size_t index, Reader value)
	{
		import capnproto.StructReader;
		int pointer = (this.ptr + cast(int)(cast(long)index * this.step / Constants.BITS_PER_BYTE)) / Constants.BYTES_PER_WORD;
		static if(is(Reader : Data.Reader))
			WireHelpers.setDataPointer(pointer, this.segment, value);
		else static if(is(Reader : Text.Reader))
			WireHelpers.setTextPointer(pointer, this.segment, value);
		else
			WireHelpers.setStructPointer(this.segment, pointer, cast(StructReader)value);
	}

package: //Variables.
	SegmentBuilder* segment;
	int ptr; //Byte offset to front of list.
	int elementCount;
	int step; //In bits.
	int structDataSize; //In bits.
	short structPointerCount;
}
