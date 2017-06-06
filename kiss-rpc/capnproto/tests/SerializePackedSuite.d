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

module capnproto.tests.SerializePackedSuite;

import java.nio.ByteBuffer;

import capnproto;

void expectPacksTo(ubyte[] unpacked, ubyte[] packed)
{
	// ----
	// write
	{
		auto bytes = new ubyte[](packed.length);
		auto writer = new ArrayOutputStream(bytes);
		auto packedOutputStream = new PackedOutputStream(writer);
		auto wrapped = ByteBuffer(unpacked);
		packedOutputStream.write(wrapped);
		
		assert(bytes == packed);
	}
	
	// ------
	// read
	{
		auto reader = new ArrayInputStream(ByteBuffer(packed));
		auto packedInputStream = new PackedInputStream(reader);
		auto bytes = new ubyte[](unpacked.length);
		auto wrapped = ByteBuffer(bytes);
		auto n = packedInputStream.read(wrapped);
		
		assert(n == unpacked.length);
		assert(bytes == unpacked);
	}
}

//SimplePacking
unittest
{
	expectPacksTo([], []);
	expectPacksTo([0,0,0,0,0,0,0,0], [0,0]);
	expectPacksTo([0,0,12,0,0,34,0,0], [0x24,12,34]);
	expectPacksTo([1,3,2,4,5,7,6,8], [0xff,1,3,2,4,5,7,6,8,0]);
	expectPacksTo([0,0,0,0,0,0,0,0, 1,3,2,4,5,7,6,8], [0,0,0xff,1,3,2,4,5,7,6,8,0]);
	expectPacksTo([0,0,12,0,0,34,0,0, 1,3,2,4,5,7,6,8], [0x24, 12, 34, 0xff,1,3,2,4,5,7,6,8,0]);
	expectPacksTo([1,3,2,4,5,7,6,8, 8,6,7,4,5,2,3,1], [0xff,1,3,2,4,5,7,6,8,1,8,6,7,4,5,2,3,1]);
	
	expectPacksTo([1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 0,2,4,0,9,0,5,1],
	              [0xff,1,2,3,4,5,6,7,8, 3, 1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 0xd6,2,4,9,5,1]);
	
	expectPacksTo([1,2,3,4,5,6,7,8, 1,2,3,4,5,6,7,8, 6,2,4,3,9,0,5,1, 1,2,3,4,5,6,7,8, 0,2,4,0,9,0,5,1],
	              [0xff,1,2,3,4,5,6,7,8, 3, 1,2,3,4,5,6,7,8, 6,2,4,3,9,0,5,1, 1,2,3,4,5,6,7,8, 0xd6,2,4,9,5,1]);
	
	expectPacksTo([8,0,100,6,0,1,1,2, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,1,0,2,0,3,1],
	              [0xed,8,100,6,1,1,2, 0,2, 0xd4,1,2,3,1]);
	
	expectPacksTo([0,0,0,0,2,0,0,0, 0,0,0,0,0,0,1,0, 0,0,0,0,0,0,0,0], [0x10,2, 0x40,1, 0,0]);
	
	import std.array : replicate;
	
	expectPacksTo([cast(ubyte)0].replicate(8 * 200), [cast(ubyte)0, 199]);
	
	expectPacksTo([cast(ubyte)1].replicate(8 * 200), cast(ubyte[])[0xff, 1,1,1,1,1,1,1,1, 199] ~ [cast(ubyte)1].replicate(8 * 199));
}
