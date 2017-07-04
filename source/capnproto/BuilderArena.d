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

module capnproto.BuilderArena;

import std.array : Appender;

import java.nio.ByteBuffer;

import capnproto.Arena;
import capnproto.Constants;
import capnproto.SegmentBuilder;
import capnproto.SegmentReader;

final class BuilderArena : Arena
{
public: //Types.
	enum AllocationStrategy
	{
		FIXED_SIZE,
		GROW_HEURISTICALLY
	}
	
	struct AllocateResult
	{
		SegmentBuilder* segment;
		
		//Offset to the beginning the of allocated memory.
		int offset;
		
		this(SegmentBuilder* segment, int offset)
		{
			this.segment = segment;
			this.offset = offset;
		}
	}

public: //Variables.
	enum SUGGESTED_FIRST_SEGMENT_WORDS = 1024;
	enum SUGGESTED_ALLOCATION_STRATEGY = AllocationStrategy.GROW_HEURISTICALLY;
	
	Appender!(SegmentBuilder[]) segments;
	
	int nextSize;
	AllocationStrategy allocationStrategy;

public: //Methods.
	this(int firstSegmentSizeWords, AllocationStrategy allocationStrategy)
	{
		this.nextSize = firstSegmentSizeWords;
		this.allocationStrategy = allocationStrategy;
		auto segment0 = SegmentBuilder(ByteBuffer(new ubyte[](firstSegmentSizeWords * Constants.BYTES_PER_WORD)), this);
		this.segments ~= segment0;
	}
	
	SegmentReader* tryGetSegment(int id)
	{
		return this.segments.data[id].asReader();
	}
	
	SegmentBuilder* getSegment(int id)
	{
		return &this.segments.data[id];
	}
	
	void checkReadLimit(int numBytes)
	{
		
	}
	
	AllocateResult allocate(int amount)
	{
		import std.algorithm : max;
		auto len = this.segments.data.length;
		//We allocate the first segment in the constructor.
		
		auto result = this.segments.data[$-1].allocate(amount);
		if(result != SegmentBuilder.FAILED_ALLOCATION)
			return AllocateResult(&this.segments.data[$-1], cast(int)result);
		
		//allocate_owned_memory.
		auto size = max(amount, this.nextSize);
		auto newSegment = SegmentBuilder(ByteBuffer(new ubyte[](size * Constants.BYTES_PER_WORD)), this);
		
		switch(this.allocationStrategy) with(AllocationStrategy)
		{
			case GROW_HEURISTICALLY:
				this.nextSize += size;
				break;
			default:
				break;
		}
		
		// --------
		
		newSegment.id = cast(int)len;
		this.segments ~= newSegment;
		
		return AllocateResult(&this.segments.data[$-1], cast(int)this.segments.data[$-1].allocate(amount));
	}
	
	ByteBuffer[] getSegmentsForOutput()
	{
		auto result = new ByteBuffer[](this.segments.data.length);
		foreach(ii; 0..this.segments.data.length)
		{
			auto segment = segments.data[ii];
			segment.buffer.rewind();
			auto slice = segment.buffer.slice();
			slice.limit = segment.currentSize() * Constants.BYTES_PER_WORD;
			result[ii] = slice;
		}
		return result;
	}
}
