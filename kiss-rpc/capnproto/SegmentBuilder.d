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

module capnproto.SegmentBuilder;

import java.nio.ByteBuffer;

import capnproto.Arena;
import capnproto.BuilderArena;
import capnproto.Constants;
import capnproto.SegmentReader;

struct SegmentBuilder
{
public: //Variables.
	static int FAILED_ALLOCATION = -1;
	
	size_t pos = 0; //In words.
	int id = 0;

public: //Methods.
	this(ByteBuffer buf, Arena arena)
	{
		reader = SegmentReader(buf, arena);
	}
	
	///Returns how many words have already been allocated.
	size_t currentSize() const
	{
		return this.pos;
	}
	
	///Allocate `amount` words.
	size_t allocate(size_t amount)
	{
		assert(amount >= 0, "Tried to allocate a negative number of words.");
		if(amount > this.capacity() - this.pos)
			return FAILED_ALLOCATION; //No space left.
		scope(exit) this.pos += amount;
		return this.pos;
	}
	
	BuilderArena getArena()
	{
		return cast(BuilderArena)reader.arena;
	}
	
	bool isWritable() const
	{
		//TODO: Support external non-writable segments.
		return true;
	}
	
	void put(int index, long value)
	{
		buffer.put!long(index * Constants.BYTES_PER_WORD, value);
	}
	
	SegmentReader* asReader()
	{
		return &reader;
	}
	
	alias reader this;

package: //Variables.
	SegmentReader reader;

private: //Methods.
	///The total number of words the buffer can hold.
	size_t capacity()
	{
		this.buffer.rewind();
		return this.buffer.remaining() / 8;
	}
}
