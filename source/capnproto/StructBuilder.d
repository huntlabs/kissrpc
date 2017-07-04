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

module capnproto.StructBuilder;

import std.string : startsWith;
import std.traits;

import java.nio.ByteBuffer;

import capnproto.AnyPointer;
import capnproto.Constants;
import capnproto.Data;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;
import capnproto.StructList;
import capnproto.StructReader;
import capnproto.StructSize;
import capnproto.Text;
import capnproto.WireHelpers;

struct StructBuilder
{
public: //Variables.
	SegmentBuilder* segment;
	int data; //Byte offset to data section.
	int pointers; //Word offset of pointer section.
	int dataSize; //In bits.
	short pointerCount;

public: //Methods.
	this(SegmentBuilder* segment, int data, int pointers, int dataSize, short pointerCount)
	{
		this.segment = segment;
		this.data = data;
		this.pointers = pointers;
		this.dataSize = dataSize;
		this.pointerCount = pointerCount;
	}
	
	T asReader(T)()
	{
		return T(segment.asReader(), data, pointers, dataSize, pointerCount, 0x7fffffff);
	}
	
	bool _getBoolField(int offset)
	{
		int bitOffset = offset;
		int position = this.data + (bitOffset / 8);
		return (this.segment.buffer.get!ubyte(position) & (1 << (bitOffset % 8))) != 0;
	}
	
	bool _getBoolField(int offset, bool mask)
	{
		return this._getBoolField(offset) ^ mask;
	}
	
	void _setBoolField(int offset, bool value)
	{
		int bitOffset = offset;
		byte bitnum = cast(byte)(bitOffset % 8);
		int position = this.data + (bitOffset / 8);
		byte oldValue = this.segment.buffer.get!byte(position);
		this.segment.buffer.put!ubyte(position, cast(byte)((oldValue & (~(1 << bitnum))) | ((value? 1 : 0) << bitnum)));
	}
	
	void _setBoolField(int offset, bool value, bool mask)
	{
		this._setBoolField(offset, value ^ mask);
	}
	
	byte _getByteField(int offset)
	{
		return this.segment.buffer.get!byte(this.data + offset);
	}
	
	byte _getByteField(int offset, byte mask)
	{
		return cast(byte)(this._getByteField(offset) ^ mask);
	}
	
	void _setByteField(int offset, byte value)
	{
		this.segment.buffer.put!byte(this.data + offset, value);
	}
	
	void _setByteField(int offset, byte value, byte mask)
	{
		this._setByteField(offset, cast(byte)(value ^ mask));
	}
	
	ubyte _getUbyteField(int offset)
	{
		return this.segment.buffer.get!ubyte(this.data + offset);
	}
	
	ubyte _getUbyteField(int offset, ubyte mask)
	{
		return cast(ubyte)(this._getByteField(offset) ^ mask);
	}
	
	void _setUbyteField(int offset, ubyte value)
	{
		this.segment.buffer.put!ubyte(this.data + offset, value);
	}
	
	void _setUbyteField(int offset, ubyte value, ubyte mask)
	{
		this._setUbyteField(offset, cast(ubyte)(value ^ mask));
	}
	
	short _getShortField(int offset)
	{
		return this.segment.buffer.get!short(this.data + offset * 2);
	}
	
	short _getShortField(int offset, short mask)
	{
		return cast(short)(this._getShortField(offset) ^ mask);
	}
	
	void _setShortField(int offset, short value)
	{
		this.segment.buffer.put!short(this.data + offset * 2, value);
	}
	
	void _setShortField(int offset, short value, short mask)
	{
		this._setShortField(offset, cast(short)(value ^ mask));
	}
	
	ushort _getUshortField(int offset)
	{
		return this.segment.buffer.get!short(this.data + offset * 2);
	}
	
	ushort _getUshortField(int offset, ushort mask)
	{
		return cast(ushort)(this._getShortField(offset) ^ mask);
	}
	
	void _setUshortField(int offset, ushort value)
	{
		this.segment.buffer.put!short(this.data + offset * 2, value);
	}
	
	void _setUshortField(int offset, ushort value, ushort mask)
	{
		this._setShortField(offset, cast(ushort)(value ^ mask));
	}
	
	int _getIntField(int offset)
	{
		return this.segment.buffer.get!int(this.data + offset * 4);
	}
	
	int _getIntField(int offset, int mask)
	{
		return this._getIntField(offset) ^ mask;
	}
	
	void _setIntField(int offset, int value)
	{
		this.segment.buffer.put!int(this.data + offset * 4, value);
	}
	
	void _setIntField(int offset, int value, int mask)
	{
		this._setIntField(offset, value ^ mask);
	}
	
	uint _getUintField(int offset)
	{
		return this.segment.buffer.get!int(this.data + offset * 4);
	}
	
	uint _getUintField(int offset, uint mask)
	{
		return this._getIntField(offset) ^ mask;
	}
	
	void _setUintField(int offset, uint value)
	{
		this.segment.buffer.put!int(this.data + offset * 4, value);
	}
	
	void _setUintField(int offset, uint value, uint mask)
	{
		this._setIntField(offset, value ^ mask);
	}
	
	long _getLongField(int offset)
	{
		return this.segment.buffer.get!long(this.data + offset * 8);
	}
	
	long _getLongField(int offset, long mask)
	{
		return this._getLongField(offset) ^ mask;
	}
	
	void _setLongField(int offset, long value)
	{
		this.segment.buffer.put!long(this.data + offset * 8, value);
	}
	
	void _setLongField(int offset, long value, long mask)
	{
		this._setLongField(offset, value ^ mask);
	}
	
	ulong _getUlongField(int offset)
	{
		return this.segment.buffer.get!long(this.data + offset * 8);
	}
	
	ulong _getUlongField(int offset, ulong mask)
	{
		return this._getLongField(offset) ^ mask;
	}
	
	void _setUlongField(int offset, ulong value)
	{
		this.segment.buffer.put!long(this.data + offset * 8, value);
	}
	
	void _setUlongField(int offset, ulong value, ulong mask)
	{
		this._setLongField(offset, value ^ mask);
	}
	
	float _getFloatField(int offset)
	{
		return this.segment.buffer.get!float(this.data + offset * 4);
	}
	
	float _getFloatField(int offset, int mask)
	{
		return intBitsToFloat(this.segment.buffer.get!int(this.data + offset * 4) ^ mask);
	}
	
	void _setFloatField(int offset, float value)
	{
		this.segment.buffer.put!float(this.data + offset * 4, value);
	}
	
	void _setFloatField(int offset, float value, int mask)
	{
		this.segment.buffer.put!int(this.data + offset * 4, floatToIntBits(value) ^ mask);
	}
	
	double _getDoubleField(int offset)
	{
		return this.segment.buffer.get!double(this.data + offset * 8);
	}
	
	double _getDoubleField(int offset, long mask)
	{
		return longBitsToDouble(this.segment.buffer.get!long(this.data + offset * 8) ^ mask);
	}
	
	void _setDoubleField(int offset, double value)
	{
		this.segment.buffer.put!double(this.data + offset * 8, value);
	}
	
	void _setDoubleField(int offset, double value, long mask)
	{
		this.segment.buffer.put!long(this.data + offset * 8, doubleToLongBits(value) ^ mask);
	}
	
	bool _pointerFieldIsNull(int ptrIndex)
	{
		return this.segment.buffer.get!long((this.pointers + ptrIndex) * Constants.BYTES_PER_WORD) == 0;
	}
	
	void _clearPointerField(int ptrIndex)
	{
		int pointer = this.pointers + ptrIndex;
		WireHelpers.zeroObject(this.segment, pointer);
		this.segment.buffer.put!long(pointer * 8, 0L);
	}
	
	T.Builder _getPointerField(T)(int index)
	{
		alias name = fullyQualifiedName!T;
		
		static if(is(T : AnyPointer))
			return T.Builder(this.segment, this.pointers + index);
		else static if(is(T : Data))
			return WireHelpers.getWritableDataPointer(this.pointers + index, this.segment, null, 0, 0);
		else static if(is(T : Text))
			return WireHelpers.getWritableTextPointer(this.pointers + index, this.segment, null, 0, 0);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.getWritableListPointer!(T.Builder)(this.pointers + index, this.segment, T.elementSize, null, 0);
		else
			return WireHelpers.getWritableStructPointer!(T.Builder)(this.pointers + index, this.segment, T.structSize, null, 0);
	}
	
	T.Builder _getPointerField(T)(int index, SegmentReader* defaultSegment, int defaultOffset)
	{
		alias name = fullyQualifiedName!T;
		
		static if(is(T : Data))
			return WireHelpers.getWritableDataPointer(this.pointers + index, this.segment, defaultSegment, defaultOffset, 0);
		else static if(is(T : Text))
			return WireHelpers.getWritableTextPointer(this.pointers + index, this.segment, defaultSegment, defaultOffset, 0);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.getWritableListPointer!(T.Builder)(this.pointers + index, this.segment, T.elementSize, defaultSegment, defaultOffset);
		else static if(name.startsWith("capnproto.StructList"))
			return WireHelpers.getWritableStructListPointer!(T.Builder)(this.pointers + index, this.segment, T.structSize, defaultSegment, defaultOffset);
		else
			return WireHelpers.getWritableStructPointer!(T.Builder)(this.pointers + index, this.segment, T.structSize, defaultSegment, defaultOffset);
	}
	
	T.Builder _getPointerField(T)(int index, ByteBuffer* defaultBuffer, int defaultOffset, int defaultSize)
	{
		static if(is(T : Data))
			return WireHelpers.getWritableDataPointer(this.pointers + index, this.segment, defaultBuffer, defaultOffset, defaultSize);
		else static if(is(T : Text))
			return WireHelpers.getWritableTextPointer(this.pointers + index, this.segment, defaultBuffer, defaultOffset, defaultSize);
		else
			static assert(0);
	}
	
	T.Builder _initPointerField(T)(int index, int elementCount)
	{
		alias name = fullyQualifiedName!T;
		
		static if(is(T : AnyPointer))
		{
			auto result = T.Builder(this.segment, this.pointers + index);
			result.clear();
			return result;
		}
		else static if(is(T : Data))
			return WireHelpers.initDataPointer(this.pointers + index, this.segment, elementCount);
		else static if(is(T : Text))
			return WireHelpers.initTextPointer(this.pointers + index, this.segment, elementCount);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.TextList"))
			return WireHelpers.initListPointer!(T.Builder)(this.pointers + index, this.segment, elementCount, T.elementSize);
		else static if(name.startsWith("capnproto.StructList"))
			return WireHelpers.initStructListPointer!(T.Builder)(this.pointers + index, this.segment, elementCount, T.structSize);
		else
			return WireHelpers.initStructPointer!(T.Builder)(this.pointers + index, this.segment, T.structSize);
	}
	
	void _setPointerField(T)(int index, T.Reader value)
	{
		alias name = fullyQualifiedName!T;
		
		static if(is(T : AnyPointer))
			assert(0);
		else static if(is(T : Data))
			WireHelpers.setDataPointer(this.pointers + index, this.segment, value);
		else static if(is(T : Text))
			WireHelpers.setTextPointer(this.pointers + index, this.segment, value);
		else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
			WireHelpers.setListPointer(this.segment, this.pointers + index, value.b);
		else
			WireHelpers.setStructPointer(this.segment, this.pointers + index, value.b);
	}
}
