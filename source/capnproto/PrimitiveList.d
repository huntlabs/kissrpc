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

module capnproto.PrimitiveList;

import capnproto.ElementSize;
import capnproto.ListBuilder;
import capnproto.ListReader;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;
import capnproto.Void;

struct PrimitiveList(Type)
{
	static if(is(Type == Void))
		enum elementSize = ElementSize.VOID;
	else static if(is(Type == bool))
		enum elementSize = ElementSize.BIT;
	else static if(is(Type == byte) || is(Type == ubyte))
		enum elementSize = ElementSize.BYTE;
	else static if(is(Type == short) || is(Type == ushort))
		enum elementSize = ElementSize.TWO_BYTES;
	else static if(is(Type == int) || is(Type == uint) || is(Type == float))
		enum elementSize = ElementSize.FOUR_BYTES;
	else static if(is(Type == long) || is(Type == ulong) || is(Type == double))
		enum elementSize = ElementSize.EIGHT_BYTES;
	
	static struct Reader
	{
	public: //Methods.
		this(SegmentReader* segment, int ptr, int elementCount, int step, int structDataSize, short structPointerCount, int nestingLimit)
		{
			b = ListReader(segment, ptr, elementCount, step, structDataSize, structPointerCount, nestingLimit);
		}
		
		size_t length()
		{
			return b.length;
		}
		
		Type get(size_t index)
		{
			static if(is(Type == Void))
				return .Void.VOID;
			else static if(is(Type == bool))
				return b._getBooleanElement(index);
			else static if(is(Type == byte))
				return b._getByteElement(index);
			else static if(is(Type == ubyte))
				return cast(ubyte)b._getByteElement(index);
			else static if(is(Type == short))
				return b._getShortElement(index);
			else static if(is(Type == ushort))
				return cast(ushort)b._getShortElement(index);
			else static if(is(Type == int))
				return b._getIntElement(index);
			else static if(is(Type == uint))
				return cast(uint)b._getIntElement(index);
			else static if(is(Type == float))
				return b._getFloatElement(index);
			else static if(is(Type == double))
				return b._getDoubleElement(index);
			else static if(is(Type == long))
				return b._getLongElement(index);
			else static if(is(Type == ulong))
				return cast(ulong)b._getLongElement(index);
		}
		
		Type opIndex(size_t index)
		{
			return get(index);
		}
		
		int opApply(scope int delegate(Type) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(opIndex(i));
				if(result)
					break;
			}
			return result;
		}
		
		int opApply(scope int delegate(size_t,Type) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(i, opIndex(i));
				if(result)
					break;
			}
			return result;
		}
	
	package: //Variables.
		ListReader b;
	}
	
	static struct Builder
	{
	public: //Methods.
		this(SegmentBuilder* segment, int ptr, int elementCount, int step, int structDataSize, short structPointerCount)
		{
			b = ListBuilder(segment, ptr, elementCount, step, structDataSize, structPointerCount);
		}
		
		size_t length()
		{
			return b.length;
		}
		
		Type get(size_t index)
		{
			static if(is(Type == Void))
				return .Void.VOID;
			else static if(is(Type == bool))
				return b._getBooleanElement(index);
			else static if(is(Type == byte))
				return b._getByteElement(index);
			else static if(is(Type == ubyte))
				return cast(ubyte)b._getByteElement(index);
			else static if(is(Type == short))
				return b._getShortElement(index);
			else static if(is(Type == ushort))
				return cast(ushort)b._getShortElement(index);
			else static if(is(Type == int))
				return b._getIntElement(index);
			else static if(is(Type == uint))
				return cast(uint)b._getIntElement(index);
			else static if(is(Type == float))
				return b._getFloatElement(index);
			else static if(is(Type == double))
				return b._getDoubleElement(index);
			else static if(is(Type == long))
				return b._getLongElement(index);
			else static if(is(Type == ulong))
				return cast(ulong)b._getLongElement(index);
		}
		
		Type opIndex(size_t index)
		{
			return get(index);
		}
		
		void set(int index, Type value)
		{
			static if(is(Type == Void)) {}
				//static assert(0, "Cannot set Void!");
			else static if(is(Type == bool))
				b._setBooleanElement(index, value);
			else static if(is(Type == byte))
				b._setByteElement(index, value);
			else static if(is(Type == ubyte))
				b._setByteElement(index, value);
			else static if(is(Type == short))
				b._setShortElement(index, value);
			else static if(is(Type == ushort))
				b._setShortElement(index, value);
			else static if(is(Type == int))
				b._setIntElement(index, value);
			else static if(is(Type == uint))
				b._setIntElement(index, value);
			else static if(is(Type == float))
				b._setFloatElement(index, value);
			else static if(is(Type == double))
				b._setDoubleElement(index, value);
			else static if(is(Type == long))
				b._setLongElement(index, value);
			else static if(is(Type == ulong))
				b._setLongElement(index, value);
		}
	
	package: //Variables.
		ListBuilder b;
	}
}
