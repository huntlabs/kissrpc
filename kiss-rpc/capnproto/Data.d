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

module capnproto.Data;

import java.nio.ByteBuffer;

import capnproto.SegmentBuilder;
import capnproto.SegmentReader;
import capnproto.WireHelpers;

struct Data
{
public: //Types.
	static struct Reader
	{
	public: //Variables.
		ByteBuffer buffer;
		int offset; //In bytes.
		size_t size; //In bytes.
	
	public: //Methods.
		this(ByteBuffer buffer, int offset, int size)
		{
			this.buffer = buffer;
			this.offset = offset * 8;
			this.size = size;
		}
		
		this(ubyte[] bytes)
		{
			this.buffer = ByteBuffer(bytes);
			this.offset = 0;
			this.size = bytes.length;
		}
		
		size_t length()
		{
			return this.size;
		}
		
		ByteBuffer asByteBuffer()
		{
			auto dup = this.buffer;
			dup.position = this.offset;
			auto result = dup.slice();
			result.limit = this.size;
			return result;
		}
		
		ubyte[] toArray()
		{
			return this.buffer[offset..offset+size];
		}
	}
	
	static struct Builder
	{
	public: //Variables.
		ByteBuffer buffer;
		int offset; //In bytes.
		int size; //In bytes.
	
	public: //Methods.
		this(ByteBuffer buffer, int offset, int size)
		{
			this.buffer = buffer;
			this.offset = offset;
			this.size = size;
		}
		
		ByteBuffer asByteBuffer()
		{
			auto dup = this.buffer;
			dup.position = this.offset;
			auto result = dup.slice();
			result.limit = this.size;
			return result;
		}
		
		ubyte[] toArray()
		{
			return this.buffer[offset..offset+size];
		}
	}
}
