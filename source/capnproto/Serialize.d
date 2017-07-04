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

module capnproto.Serialize;

import std.array : Appender;

import java.io.IOException;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;
import java.nio.ByteBuffer;

import capnproto.Constants;
import capnproto.DecodeException;
import capnproto.MessageBuilder;
import capnproto.MessageReader;
import capnproto.ReaderOptions;

struct Serialize
{
public: //Methods.
	static void fillBuffer(ref ByteBuffer buffer, ReadableByteChannel bc)
	{
		while(!buffer.empty())
		{
			auto r = bc.read(buffer);
			if(r < 0)
				throw new IOException("Premature EOF.");
			if(r == 0)
				break;
		}
	}
	
	static MessageReader read(ReadableByteChannel bc)
	{
		return read(bc, cast(ReaderOptions)ReaderOptions.DEFAULT_READER_OPTIONS);
	}
	
	static MessageReader read(ReadableByteChannel bc, ReaderOptions options)
	{
		auto firstWord = makeByteBuffer(Constants.BYTES_PER_WORD);
		fillBuffer(firstWord, bc);
		
		int segmentCount = 1 + firstWord.get!int(0);
		
		int segment0Size = 0;
		if(segmentCount > 0)
			segment0Size = firstWord.get!int(4);
		
		int totalWords = segment0Size;
		
		if(segmentCount > 512)
			throw new IOException("Too many segments.");
		
		//In words.
		Appender!(int[]) moreSizes;
		
		if(segmentCount > 1)
		{
			auto moreSizesRaw = makeByteBuffer(4 * (segmentCount & ~1));
			fillBuffer(moreSizesRaw, bc);
			foreach(ii; 0..segmentCount-1)
			{
				int size = moreSizesRaw.get!int(ii * 4);
				moreSizes ~= size;
				totalWords += size;
			}
		}
		
		if(totalWords > options.traversalLimitInWords)
			throw new DecodeException("Message size exceeds traversal limit.");
		
		auto allSegments = makeByteBuffer(totalWords * Constants.BYTES_PER_WORD);
		fillBuffer(allSegments, bc);
		
		auto segmentSlices = new ByteBuffer[](segmentCount);
		
		allSegments.rewind();
		segmentSlices[0] = allSegments.slice();
		segmentSlices[0].limit = segment0Size * Constants.BYTES_PER_WORD;
		
		int offset = segment0Size;
		foreach(ii; 1..segmentCount)
		{
			allSegments.position = offset * Constants.BYTES_PER_WORD;
			segmentSlices[ii] = allSegments.slice();
			segmentSlices[ii].limit = moreSizes.data[ii - 1] * Constants.BYTES_PER_WORD;
			offset += moreSizes.data[ii - 1];
		}
		
		return new MessageReader(segmentSlices, options);
	}
	
	static MessageReader read(ref ByteBuffer bb)
	{
		return read(bb, cast(ReaderOptions)ReaderOptions.DEFAULT_READER_OPTIONS);
	}
	
	///Upon return, `bb.position()` will be at the end of the message.
	static MessageReader read(ref ByteBuffer bb, ReaderOptions options)
	{
		int segmentCount = 1 + bb.get!int();
		if(segmentCount > 512)
			throw new IOException("Too many segments.");
		
		auto segmentSlices = new ByteBuffer[](segmentCount);
		
		auto segmentSizesBase = bb.position;
		int segmentSizesSize = segmentCount * 4;
		
		int align_ = Constants.BYTES_PER_WORD - 1;
		auto segmentBase = (segmentSizesBase + segmentSizesSize + align_) & ~align_;
		
		int totalWords = 0;
		
		foreach(ii; 0..segmentCount)
		{
			int segmentSize = bb.get!int(segmentSizesBase + ii * 4);
			
			bb.position = segmentBase + totalWords * Constants.BYTES_PER_WORD;
			segmentSlices[ii] = bb.slice();
			segmentSlices[ii].limit = segmentSize * Constants.BYTES_PER_WORD;
			
			totalWords += segmentSize;
		}
		bb.position = segmentBase + totalWords * Constants.BYTES_PER_WORD;
		
		if(totalWords > options.traversalLimitInWords)
			throw new DecodeException("Message size exceeds traversal limit.");
		
		return new MessageReader(segmentSlices, options);
	}
	
	static long computeSerializedSizeInWords(MessageBuilder message)
	{
		auto segments = message.getSegmentsForOutput();
		
		//From the capnproto documentation:
		//"When transmitting over a stream, the following should be sent..."
		long bytes = 0;
		//"(4 bytes) The number of segments, minus one..."
		bytes += 4;
		//"(N * 4 bytes) The size of each segment, in words."
		bytes += segments.length * 4;
		//"(0 or 4 bytes) Padding up to the next word boundary."
		if(bytes % 8 != 0)
			bytes += 4;
		
		//The content of each segment, in order.
		foreach(i; 0..segments.length)
		{
			auto s = segments[i];
			bytes += s.limit;
		}
		
		return bytes / Constants.BYTES_PER_WORD;
	}
	
	static void write(WritableByteChannel outputChannel, MessageBuilder message)
	{
		auto segments = message.getSegmentsForOutput();
		auto tableSize = (segments.length + 2) & (~1);
		
		auto table = ByteBuffer(new ubyte[](4 * tableSize));
		
		table.put!int(0, cast(int)(segments.length-1));
		
		foreach(i; 0..segments.length)
			table.put!int(4 * (i + 1), cast(int)(segments[i].limit/8));
		
		//Any padding is already zeroed.
		while(!table.empty())
			outputChannel.write(table);
		
		foreach(buffer; segments)
		{
			while(!buffer.empty())
				outputChannel.write(buffer);
		}
	}

private: //Methods.
	static ByteBuffer makeByteBuffer(int bytes)
	{
		auto result = ByteBuffer.prepare(bytes);
		//result.mark(); //TODO: Is this used for anything?
		return result;
	}
}
