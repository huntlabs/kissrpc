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

module capnproto.EnumList;

import capnproto.ElementSize;
import capnproto.ListBuilder;
import capnproto.ListReader;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;

struct EnumList(T)
{
	enum elementSize = ElementSize.TWO_BYTES;

public:
	static struct Reader
	{
	public: //Methods.
		this(SegmentReader* segment, int ptr, int elementCount, int step, int structDataSize, short structPointerCount, int nestingLimit)
		{
			b = ListReader(segment, ptr, elementCount, step, structDataSize, structPointerCount, nestingLimit);
		}
		
		T get(int index)
		{
			return clampOrdinal!T(b._getShortElement(index));
		}
		
		int opApply(scope int delegate(T) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(clampOrdinal!T(b._getShortElement(i)));
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
		
		T get(int index)
		{
			return clampOrdinal!T(b._getShortElement(index));
		}
		
		void set(int index, T value)
		{
			b._setShortElement(index, cast(short)value);
		}
		
		int opApply(scope int delegate(T) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(clampOrdinal!T(b._getShortElement(i)));
				if(result)
					break;
			}
			return result;
		}
	
	package: //Variables.
		ListBuilder b;
	}
}

private T clampOrdinal(T)(ushort ordinal)
{
	size_t index = ordinal;
	if(ordinal < 0 || ordinal >= T.max)
		index = T.max - 1;
	return cast(T)index;
}
