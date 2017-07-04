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

module capnproto.DataList;

import capnproto.Data;
import capnproto.ElementSize;
import capnproto.ListBuilder;
import capnproto.ListReader;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;

struct DataList
{
	enum elementSize = ElementSize.POINTER;

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
		
		Data.Reader get(int index)
		{
			return b._getPointerElement!Data(index);
		}
		
		int opApply(scope int delegate(Data.Reader) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(b._getPointerElement!Data(i));
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
		
		Data.Builder get(int index)
		{
			return b._getPointerElement!Data(index);
		}
		
		void set(int index, Data.Reader value)
		{
			b._setPointerElement!(Data.Reader)(index, value);
		}
		
		int opApply(scope int delegate(Data.Builder) dg)
		{
			int result = 0;
			foreach(i; 0..b.length)
			{
				result = dg(b._getPointerElement!Data(i));
				if(result)
					break;
			}
			return result;
		}
	
	package: //Variables.
		ListBuilder b;
	}
}
