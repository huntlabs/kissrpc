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

module capnproto.Void;

import capnproto.ElementSize;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;

/*enum Void
{
	VOID
}*/

struct Void
{
	enum elementSize = ElementSize.VOID;
	enum Void VOID = Void();
	
	static struct Reader
	{
		this(SegmentReader* segment, int data, int pointers, int dataSize, short pointerCount, int nestingLimit)
		{
			
		}
		
		Void get(int index)
		{
			assert(0);
		}
		
		Void opIndex(size_t index)
		{
			assert(0);
		}
	}
	
	static struct Builder
	{
		this(SegmentBuilder* segment, int data, int pointers, int dataSize, short pointerCount)
		{
			
		}
		
		Void get(int index)
		{
			assert(0);
		}
		
		Void opIndex(size_t index)
		{
			assert(0);
		}
		
		void set(Void value)
		{
			assert(0);
		}
	}
}
