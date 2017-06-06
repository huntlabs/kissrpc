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

module capnproto.AnyPointer;

import std.string : startsWith;
import std.traits;

import capnproto.Data;
import capnproto.Constants;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;
import capnproto.Text;
import capnproto.WireHelpers;
import capnproto.WirePointer;

struct AnyPointer
{
public: //Types.
	static struct Reader
	{
	public: //Methods.
		this(const(SegmentReader)* segment, int pointer, int nestingLimit)
		{
			this.segment = segment;
			this.pointer = pointer;
			this.nestingLimit = nestingLimit;
		}
		
		bool isNull()
		{
			return WirePointer.isNull(this.segment.buffer.get!long(this.pointer * Constants.BYTES_PER_WORD));
		}
		
		T.Reader getAs(T)()
		{
			alias name = fullyQualifiedName!T;
			static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
				return WireHelpers.readListPointer!(T.Reader)(cast(SegmentReader*)this.segment, this.pointer, null, 0, T.elementSize, this.nestingLimit);
			else
				return WireHelpers.readStructPointer!(T.Reader)(cast(SegmentReader*)this.segment, this.pointer, null, 0, this.nestingLimit);
			//return factory.fromPointerReader(this.segment, this.pointer, this.nestingLimit);
		}
	
	private: //Variables.
		const(SegmentReader)* segment;
		int pointer; //Offset in words.
		int nestingLimit;
	}
	
	static struct Builder
	{
	public: //Methods.
		this(SegmentBuilder* segment, int pointer)
		{
			this.segment = segment;
			this.pointer = pointer;
		}
		
		bool isNull()
		{
			return WirePointer.isNull(this.segment.buffer.get!long(this.pointer * Constants.BYTES_PER_WORD));
		}
		
		T.Builder getAs(T)()
		{
			alias name = fullyQualifiedName!T;
			
			static if(is(T : Data))
				return WireHelpers.getWritableDataPointer(this.pointer, this.segment, null, 0, 0);
			else static if(is(T : Text))
				return WireHelpers.getWritableTextPointer(this.pointer, this.segment, null, 0, 0);
			else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.TextList"))
				return WireHelpers.getWritableListPointer!(T.Builder)(this.pointer, this.segment, T.elementSize, null, 0);
			else static if(name.startsWith("capnproto.StructList"))
				return WireHelpers.getWritableStructListPointer!(T.Builder)(this.pointer, this.segment, T.structSize, null, 0);
			else
				return WireHelpers.getWritableStructPointer!(T.Builder)(this.pointer, this.segment, T.structSize, null, 0);
			//return fromPointerBuilder!(T.Builder)(this.segment, this.pointer);
		}
		
		T.Builder initAs(T)()
		{
			alias name = fullyQualifiedName!T;
			static if(is(T : AnyPointer))
			{
				auto result = T.Builder(this.segment, this.pointer);
				result.clear();
				return result;
			}
			else
				return WireHelpers.initStructPointer!(T.Builder)(this.pointer, this.segment, T.structSize);
			//return T.initFromPointerBuilder(this.segment, this.pointer, 0);
		}
		
		T.Builder initAs(T)(int elementCount)
		{
			alias name = fullyQualifiedName!T;
			
			static if(is(T : Data))
				return WireHelpers.initDataPointer(this.pointer, this.segment, elementCount);
			else static if(is(T : Text))
				return WireHelpers.initTextPointer(this.pointer, this.segment, elementCount);
			else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.TextList"))
				return WireHelpers.initListPointer!(T.Builder)(this.pointer, this.segment, elementCount, T.elementSize);
			else static if(name.startsWith("capnproto.StructList"))
				return WireHelpers.initStructListPointer!(T.Builder)(this.pointer, this.segment, elementCount, T.structSize);
			else
				return WireHelpers.initStructPointer!(T.Builder)(this.pointer, this.segment, elementCount);
		}
		
		void setAs(T, U)(U reader)
		{
			alias name = fullyQualifiedName!U;
			
			static if(is(T : Data))
				WireHelpers.setDataPointer(this.pointer, this.segment, reader);
			else static if(is(T : Text))
				WireHelpers.setTextPointer(this.pointer, this.segment, reader);
			else static if(name.startsWith("capnproto.DataList") || name.startsWith("capnproto.EnumList") || name.startsWith("capnproto.PrimitiveList") || name.startsWith("capnproto.ListList") || name.startsWith("capnproto.StructList") || name.startsWith("capnproto.TextList"))
				WireHelpers.setListPointer(this.segment, this.pointer, reader.b);
			else
				WireHelpers.setStructPointer(this.segment, this.pointer, reader.b);
			//factory.setPointerBuilder(this.segment, this.pointer, reader);
		}
		
		Reader asReader()
		{
			return Reader(segment.asReader(), pointer, 0x7fffffff);
		}
		
		void clear()
		{
			WireHelpers.zeroObject(this.segment, this.pointer);
			this.segment.buffer.put!long(this.pointer * 8, 0L);
		}
	
	private: //Variables.
		SegmentBuilder* segment;
		int pointer;
	}
}
