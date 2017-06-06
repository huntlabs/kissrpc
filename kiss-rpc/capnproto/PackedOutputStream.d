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

module capnproto.PackedOutputStream;

import java.io.IOException;
import java.nio.channels.WritableByteChannel;
import java.nio.ByteBuffer;

import capnproto.BufferedOutputStream;

final class PackedOutputStream : WritableByteChannel
{
public: //Methods.
	this(BufferedOutputStream output)
	{
		this.inner = output;
	}
	
	size_t write(ref ByteBuffer inBuf)
	{
		auto length = inBuf.remaining();
		auto out_ = this.inner.getWriteBuffer();
		
		auto slowBuffer = ByteBuffer(new ubyte[](20));
		
		auto inPtr = inBuf.position;
		auto inEnd = inPtr + length;
		while(inPtr < inEnd)
		{
			if(out_.remaining() < 10)
			{
				//# Oops, we're out of space. We need at least 10
				//# bytes for the fast path, since we don't
				//# bounds-check on every byte.
				
				if(out_ is &slowBuffer)
				{
					auto oldLimit = out_.limit;
					out_.limit = out_.position;
					out_.rewind();
					this.inner.write(*out_);
					out_.limit = oldLimit;
				}
				out_ = &slowBuffer;
				out_.rewind();
			}
			
			auto tagPos = out_.position;
			out_.position = tagPos + 1;
			
			import std.meta;
			ubyte bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7;
			foreach(ref b; AliasSeq!(bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7))
			{
				ubyte curByte = inBuf.get!ubyte(inPtr);
				b = (curByte != 0)? cast(ubyte)1 : cast(ubyte)0;
				out_.put!ubyte(curByte);
				out_.position += b - 1;
				inPtr += 1;
			}
			
			ubyte tag = cast(ubyte)((bit0 << 0) | (bit1 << 1) | (bit2 << 2) | (bit3 << 3) |
			                        (bit4 << 4) | (bit5 << 5) | (bit6 << 6) | (bit7 << 7));
			
			out_.put!ubyte(tagPos, tag);
			
			if(tag == 0)
			{
				//# An all-zero word is followed by a count of
				//# consecutive zero words (not including the first
				//# one).
				auto runStart = inPtr;
				auto limit = inEnd;
				if(limit - inPtr > 255 * 8)
					limit = inPtr + 255 * 8;
				while(inPtr < limit && inBuf.get!long(inPtr) == 0)
					inPtr += 8;
				out_.put!ubyte(cast(byte)((inPtr - runStart)/8));
			}
			else if(tag == 0xff)
			{
				//# An all-nonzero word is followed by a count of
				//# consecutive uncompressed words, followed by the
				//# uncompressed words themselves.
				
				//# Count the number of consecutive words in the input
				//# which have no more than a single zero-byte. We look
				//# for at least two zeros because that's the point
				//# where our compression scheme becomes a net win.
				
				auto runStart = inPtr;
				auto limit = inEnd;
				if(limit - inPtr > 255 * 8)
					limit = inPtr + 255 * 8;
				
				while(inPtr < limit)
				{
					byte c = 0;
					foreach(ii; 0..8)
					{
						c += (inBuf.get!byte(inPtr) == 0? 1 : 0);
						inPtr += 1;
					}
					if(c >= 2)
					{
						//# Un-read the word with multiple zeros, since
						//# we'll want to compress that one.
						inPtr -= 8;
						break;
					}
				}
				
				auto count = inPtr - runStart;
				out_.put!ubyte(cast(byte)(count / 8));
				
				if(count <= out_.remaining())
				{
					//# There's enough space to memcpy.
					inBuf.position = runStart;
					ByteBuffer slice = inBuf.slice();
					slice.limit = count;
					out_.put!ByteBuffer(slice);
				}
				else
				{
					//# Input overruns the output buffer. We'll give it
					//# to the output stream in one chunk and let it
					//# decide what to do.
					
					if(out_ is &slowBuffer)
					{
						auto oldLimit = out_.limit;
						out_.limit = out_.position;
						out_.rewind();
						this.inner.write(*out_);
						out_.limit = oldLimit;
					}
					
					inBuf.position = runStart;
					ByteBuffer slice = inBuf.slice();
					slice.limit = count;
					while(!slice.empty())
						this.inner.write(slice);
					out_ = this.inner.getWriteBuffer();
				}
			}
		}
		
		if(out_ is &slowBuffer)
		{
			out_.limit = out_.position;
			out_.rewind();
			this.inner.write(*out_);
		}
		
		inBuf.position = inPtr;
		return length;
	}
	
	void close()
	{
		this.inner.close();
	}
	
	bool isOpen()
	{
		return this.inner.isOpen();
	}

package: //Variables.
	BufferedOutputStream inner;
}
