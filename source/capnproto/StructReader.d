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

module capnproto.StructReader;

import std.string : startsWith;
import std.traits;

import java.nio.ByteBuffer;

import capnproto.AnyPointer;
import capnproto.Constants;
import capnproto.Data;
import capnproto.ElementSize;
import capnproto.SegmentReader;
import capnproto.StructList;
import capnproto.Text;
import capnproto.WireHelpers;

struct StructReader
{
public: //Variables.
	SegmentReader* segment;
	int data; //Byte offset to data section.
	int pointers; //Word offset of pointer section.
	int dataSize; //In bits.
	short pointerCount;
	int nestingLimit;

public: //Methods.
	this(SegmentReader* segment, int data, int pointers, int dataSize, short pointerCount, int nestingLimit)
	{
		this.segment = segment;
		this.data = data;
		this.pointers = pointers;
		this.dataSize = dataSize;
		this.pointerCount = pointerCount;
		this.nestingLimit = nestingLimit;
	}
	
	bool _getBoolField(int offset)
	{
		if(offset < this.dataSize)
		{
			ubyte b = this.segment.buffer.get!ubyte(this.data + offset / 8);
			return (b & (1 << (offset % 8))) != 0;
		}
		return false;
	}
	
	bool _getBoolField(int offset, bool mask)
	{
		return this._getBoolField(offset) ^ mask;
	}
	
	byte _getByteField(int offset)
	{
		if((offset + 1) * 8 <= this.dataSize)
			return this.segment.buffer.get!byte(this.data + offset);
		return 0;
	}
	
	byte _getByteField(int offset, byte mask)
	{
		return cast(byte)(this._getByteField(offset) ^ mask);
	}
	
	ubyte _getUbyteField(int offset)
	{
		if((offset + 1) * 8 <= this.dataSize)
			return this.segment.buffer.get!ubyte(this.data + offset);
		return 0;
	}
	
	ubyte _getUbyteField(int offset, ubyte mask)
	{
		return cast(ubyte)(this._getByteField(offset) ^ mask);
	}
	
	short _getShortField(int offset)
	{
		if((offset + 1) * 16 <= this.dataSize)
			return this.segment.buffer.get!short(this.data + offset * 2);
		return 0;
	}
	
	short _getShortField(int offset, short mask)
	{
		return cast(short)(this._getShortField(offset) ^ mask);
	}
	
	ushort _getUshortField(int offset)
	{
		if((offset + 1) * 16 <= this.dataSize)
			return cast(ushort)this.segment.buffer.get!short(this.data + offset * 2);
		return 0;
	}
	
	ushort _getUshortField(int offset, ushort mask)
	{
		return cast(ushort)(this._getUshortField(offset) ^ mask);
	}
	
	int _getIntField(int offset)
	{
		if((offset + 1) * 32 <= this.dataSize)
			return this.segment.buffer.get!int(this.data + offset * 4);
		return 0;
	}
	
	int _getIntField(int offset, int mask)
	{
		return this._getIntField(offset) ^ mask;
	}
	
	uint _getUintField(int offset)
	{
		if((offset + 1) * 32 <= this.dataSize)
			return cast(uint)this.segment.buffer.get!int(this.data + offset * 4);
		return 0;
	}
	
	uint _getUintField(int offset, uint mask)
	{
		return this._getUintField(offset) ^ mask;
	}
	
	long _getLongField(int offset)
	{
		if((offset + 1) * 64 <= this.dataSize)
			return this.segment.buffer.get!long(this.data + offset * 8);
		return 0;
	}
	
	long _getLongField(int offset, long mask)
	{
		return this._getLongField(offset) ^ mask;
	}
	
	ulong _getUlongField(int offset)
	{
		if((offset + 1) * 64 <= this.dataSize)
			return cast(ulong)this.segment.buffer.get!long(this.data + offset * 8);
		return 0;
	}
	
	ulong _getUlongField(int offset, ulong mask)
	{
		return this._getUlongField(offset) ^ mask;
	}
	
	float _getFloatField(int offset)
	{
		if((offset + 1) * 32 <= this.dataSize)
			return this.segment.buffer.get!float(this.data + offset * 4);
		return 0;
	}
	
	float _getFloatField(int offset, int mask)
	{
		if((offset + 1) * 32 <= this.dataSize)
			return intBitsToFloat(this.segment.buffer.get!int(this.data + offset * 4) ^ mask);
		return intBitsToFloat(mask);
	}
	
	double _getDoubleField(int offset)
	{
		if((offset + 1) * 64 <= this.dataSize)
			return this.segment.buffer.get!double(this.data + offset * 8);
		return 0;
	}
	
	double _getDoubleField(int offset, long mask)
	{
		if((offset + 1) * 64 <= this.dataSize)
			return longBitsToDouble(this.segment.buffer.get!long(this.data + offset * 8) ^ mask);
		return longBitsToDouble(mask);
	}
	
	bool _pointerFieldIsNull(int ptrIndex)
	{
		return this.segment.buffer.get!long((this.pointers + ptrIndex) * Constants.BYTES_PER_WORD) == 0;
	}
	
	T.Reader _getPointerField(T)(int ptrIndex)
	{
		alias name = fullyQualifiedName!T;
		auto segment = cast(SegmentReader*)&SegmentReader.EMPTY;
		int pointer = 0;
		if(ptrIndex < this.pointerCount)
		{
			segment = this.segment;
			pointer = this.pointers + ptrIndex;
		}
		static if(is(T : AnyPointer))
			return T.Reader(segment, pointer, nestingLimit);
		else static if(is(T : Data))
			return WireHelpers.readDataPointer(segment, pointer, null, 0, 0);
		else static if(is(T : Text))
			return WireHelpers.readTextPointer(segment, pointer, null, 0, 0);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.readListPointer!(T.Reader)(segment, pointer, null, 0, T.elementSize, this.nestingLimit);
		else
			return WireHelpers.readStructPointer!(T.Reader)(segment, pointer, null, 0, nestingLimit);
	}
	
	T.Reader _getPointerField(T)(int ptrIndex, SegmentReader* defaultSegment, int defaultOffset)
	{
		alias name = fullyQualifiedName!T;
		
		auto segment = cast(SegmentReader*)&SegmentReader.EMPTY;
		int pointer = 0;
		if(ptrIndex < this.pointerCount)
		{
			segment = this.segment;
			pointer = this.pointers + ptrIndex;
		}
		static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.readListPointer!(T.Reader)(segment, pointer, defaultSegment, defaultOffset, T.elementSize, this.nestingLimit);
		else
			return WireHelpers.readStructPointer!(T.Reader)(segment, pointer, defaultSegment, defaultOffset, this.nestingLimit);
	}
	
	StructList.Reader!(T.Reader) _getPointerListField(T)(int ptrIndex, SegmentReader* defaultSegment, int defaultOffset)
	{
		if(ptrIndex < this.pointerCount)
			return WireHelpers.readListPointer!(StructList.Reader!(T.Reader))(this.segment, this.pointers + ptrIndex, defaultSegment, defaultOffset, ElementSize.INLINE_COMPOSITE, this.nestingLimit);
		return WireHelpers.readListPointer!(StructList.Reader!(T.Reader))(cast(SegmentReader*)&SegmentReader.EMPTY, 0, defaultSegment, defaultOffset, ElementSize.INLINE_COMPOSITE, this.nestingLimit);
	}
	
	T.Reader _getPointerField(T)(int ptrIndex, ByteBuffer* defaultBuffer, int defaultOffset, int defaultSize)
	{
		auto segment = cast(SegmentReader*)&SegmentReader.EMPTY;
		int pointer = 0;
		if(ptrIndex < this.pointerCount)
		{
			segment = this.segment;
			pointer = this.pointers + ptrIndex;
		}
		
		static if(is(T : Data))
			return WireHelpers.readDataPointer(segment, pointer, defaultBuffer, defaultOffset, defaultSize);
		else static if(is(T : Text))
			return WireHelpers.readTextPointer(segment, pointer, defaultBuffer, defaultOffset, defaultSize);
		else
			static assert(0);
	}
}
