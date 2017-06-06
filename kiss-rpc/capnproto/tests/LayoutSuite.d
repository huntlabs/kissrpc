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

module capnproto.tests.LayoutSuite;

import java.nio.ByteBuffer;

import capnproto;

//SimpleRawDataStruct
unittest
{
	ubyte[] data = [ 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef ];
	
	auto buffer = ByteBuffer(data);
	
	auto arena = new ReaderArena([buffer], 0x7fffffffffffffffL);
	
	auto reader = WireHelpers.readStructPointer!StructReader(arena.tryGetSegment(0), 0, null, 0, 0x7fffffff);
	
	assert(reader._getLongField(0) == 0xefcdab8967452301L);
	assert(reader._getLongField(1) == 0L);
	
	assert(reader._getUintField(0) == 0x67452301);
	assert(reader._getUintField(1) == 0xefcdab89);
	assert(reader._getUintField(2) == 0);
	assert(reader._getUshortField(0) == 0x2301);
	assert(reader._getUshortField(1) == 0x6745);
	assert(reader._getUshortField(2) == 0xab89);
	assert(reader._getUshortField(3) == 0xefcd);
	assert(reader._getUshortField(4) == 0);
	
	// TODO masking
	
	assert(reader._getBoolField(0) == true);
	assert(reader._getBoolField(1) == false);
	assert(reader._getBoolField(2) == false);
	
	assert(reader._getBoolField(3) == false);
	assert(reader._getBoolField(4) == false);
	assert(reader._getBoolField(5) == false);
	assert(reader._getBoolField(6) == false);
	assert(reader._getBoolField(7) == false);
	
	assert(reader._getBoolField(8) == true);
	assert(reader._getBoolField(9) == true);
	assert(reader._getBoolField(10) == false);
	assert(reader._getBoolField(11) == false);
	assert(reader._getBoolField(12) == false);
	assert(reader._getBoolField(13) == true);
	assert(reader._getBoolField(14) == false);
	assert(reader._getBoolField(15) == false);
	
	assert(reader._getBoolField(63) == true);
	assert(reader._getBoolField(64) == false);
	
	// TODO masking
}

//StructRoundTrip_OneSegment
unittest
{
	auto buffer = ByteBuffer(new ubyte[](1024 * 8));
	
	auto segment = SegmentBuilder(buffer, new BuilderArena(BuilderArena.SUGGESTED_FIRST_SEGMENT_WORDS, BuilderArena.SUGGESTED_ALLOCATION_STRATEGY));
	auto builder = WireHelpers.initStructPointer!StructBuilder(0, &segment, cast(immutable)StructSize(2, 4));
	setupStruct(&builder);
	checkStruct(&builder);
}

void setupStruct(StructBuilder* builder)
{
	builder._setLongField(0, 0x1011121314151617L);
	builder._setIntField(2, 0x20212223);
	builder._setShortField(6, 0x3031);
	builder._setByteField(14, 0x40);
	builder._setBoolField(120, false);
	builder._setBoolField(121, false);
	builder._setBoolField(122, true);
	builder._setBoolField(123, false);
	builder._setBoolField(124, true);
	builder._setBoolField(125, true);
	builder._setBoolField(126, true);
	builder._setBoolField(127, false);
}

void checkStruct(StructBuilder* builder)
{
	assert(builder._getLongField(0) == 0x1011121314151617L);
	assert(builder._getIntField(2) == 0x20212223);
	assert(builder._getShortField(6) == 0x3031);
	assert(builder._getByteField(14) == 0x40);
	assert(builder._getBoolField(120) == false);
	assert(builder._getBoolField(121) == false);
	assert(builder._getBoolField(122) == true);
	assert(builder._getBoolField(123) == false);
	assert(builder._getBoolField(124) == true);
	assert(builder._getBoolField(125) == true);
	assert(builder._getBoolField(126) == true);
	assert(builder._getBoolField(127) == false);
}

