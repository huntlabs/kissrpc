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

module capnproto.PackedInputStream;

import java.io.IOException;
import java.nio.channels.ReadableByteChannel;
import java.nio.ByteBuffer;

import capnproto.BufferedInputStream;

final class PackedInputStream : ReadableByteChannel
{
public: //Methods.
	this(BufferedInputStream input)
	{
		this.inner = input;
	}
	
	size_t read(ref ByteBuffer outBuf)
	{
		if(outBuf.buffer is null)
			outBuf = ByteBuffer(new ubyte[](outBuf.remaining()));
		auto len = outBuf.remaining();
		if(len == 0)
			return 0;
		if(len % 8 != 0)
			throw new Error("PackedInputStream reads must be word-aligned.");
		
		auto outPtr = outBuf.position;
		auto outEnd = outPtr + len;
		
		auto inBuf = this.inner.getReadBuffer();
		
		while(true)
		{
			ubyte tag = 0;
			
			if(inBuf.remaining() < 10)
			{
				if(outBuf.remaining() == 0)
					return len;
				if(inBuf.remaining() == 0)
				{
					inBuf = this.inner.getReadBuffer();
					continue;
				}
				
				//# We have at least 1, but not 10, bytes available. We need to read
				//# slowly, doing a bounds check on each byte.
				
				tag = inBuf.get!ubyte();
				
				foreach(i; 0..8)
				{
					if((tag & (1 << i)) != 0)
					{
						if(inBuf.remaining() == 0)
							inBuf = this.inner.getReadBuffer();
						outBuf.put!ubyte(inBuf.get!ubyte());
					}
					else
						outBuf.put!ubyte(0);
				}
				
				if(inBuf.remaining() == 0 && (tag == 0 || tag == cast(byte)0xff))
					inBuf = this.inner.getReadBuffer();
			}
			else
			{
				tag = inBuf.get!ubyte();
				foreach(n; 0..8)
				{
					bool isNonzero = (tag & (1 << n)) != 0;
					outBuf.put!ubyte(cast(byte)(inBuf.get!ubyte() & (isNonzero? -1 : 0)));
					inBuf.position += isNonzero? 0 : -1;
				}
			}
			
			if(tag == 0)
			{
				if(inBuf.remaining() == 0)
					throw new Error("Should always have non-empty buffer here.");
				
				int runLength = inBuf.get!ubyte() * 8;
				if(runLength > outEnd - outPtr)
					throw new Error("Packed input did not end cleanly on a segment boundary.");
				
				foreach(i; 0..runLength)
					outBuf.put!ubyte(0);
			}
			else if(tag == 0xff)
			{
				int runLength = inBuf.get!ubyte() * 8;
				
				if(inBuf.remaining() >= runLength)
				{
					//# Fast path.
					auto slice = inBuf.slice();
					slice.limit = runLength;
					outBuf.put!ByteBuffer(slice);
					inBuf.position += runLength;
				}
				else
				{
					//# Copy over the first buffer, then do one big read for the rest.
					runLength -= inBuf.remaining();
					outBuf.put!ByteBuffer(*inBuf);
					
					auto slice = outBuf.slice();
					slice.limit = runLength;
					
					this.inner.read(slice);
					outBuf.position += runLength;
					
					if(outBuf.remaining() == 0)
						return len;
					
					inBuf = this.inner.getReadBuffer();
					continue;
				}
			}
			
			if(outBuf.remaining() == 0)
				return len;
		}
	}
	
	void close()
	{
		inner.close();
	}
	
	bool isOpen()
	{
		return inner.isOpen();
	}

private: //Variables.
	BufferedInputStream inner;
}
