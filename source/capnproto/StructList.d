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

module capnproto.StructList;

import capnproto.ElementSize;
import capnproto.ListBuilder;
import capnproto.ListReader;
import capnproto.SegmentReader;
import capnproto.SegmentBuilder;
import capnproto.StructBuilder;
import capnproto.StructReader;
import capnproto.WireHelpers;

struct StructList(T)
{
	enum elementSize = ElementSize.INLINE_COMPOSITE;
	alias structSize = T.structSize;

public: //Types.
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
		
		T.Reader get(size_t index)
		{
			return b._getStructElement!T(cast(int)index);
		}
		
		T.Reader opIndex(size_t index)
		{
			return b._getStructElement!T(cast(int)index);
		}
		
		int opApply(scope int delegate(T.Reader) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(b._getStructElement!T(i));
				if(result)
					break;
			}
			return result;
		}
		
		int opApply(scope int delegate(size_t,T.Reader) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(i, b._getStructElement!T(i));
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
		
		T.Builder get(size_t index)
		{
			return b._getStructElement!T(cast(int)index);
		}
		
		T.Builder opIndex(size_t index)
		{
			return b._getStructElement!T(cast(int)index);
		}
		
		int opApply(scope int delegate(T.Builder) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(b._getStructElement!T(i));
				if(result)
					break;
			}
			return result;
		}
	
	private: //Variables.
		ListBuilder b;
	}
}
