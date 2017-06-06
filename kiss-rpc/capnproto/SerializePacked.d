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

module capnproto.SerializePacked;

import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;

import capnproto.BufferedInputStream;
import capnproto.BufferedInputStreamWrapper;
import capnproto.BufferedOutputStream;
import capnproto.BufferedOutputStreamWrapper;
import capnproto.MessageBuilder;
import capnproto.MessageReader;
import capnproto.PackedInputStream;
import capnproto.PackedOutputStream;
import capnproto.ReaderOptions;
import capnproto.Serialize;

struct SerializePacked
{
	static MessageReader read(BufferedInputStream input)
	{
		return read(input, cast(ReaderOptions)ReaderOptions.DEFAULT_READER_OPTIONS);
	}
	
	static MessageReader read(BufferedInputStream input, ReaderOptions options)
	{
		auto packedInput = new PackedInputStream(input);
		return Serialize.read(packedInput, options);
	}
	
	static MessageReader readFromUnbuffered(ReadableByteChannel input)
	{
		return readFromUnbuffered(input, cast(ReaderOptions)ReaderOptions.DEFAULT_READER_OPTIONS);
	}
	
	static MessageReader readFromUnbuffered(ReadableByteChannel input, ReaderOptions options)
	{
		auto packedInput = new PackedInputStream(new BufferedInputStreamWrapper(input));
		return Serialize.read(packedInput, options);
	}
	
	static void write(BufferedOutputStream output, MessageBuilder message)
	{
		auto packedOutputStream = new PackedOutputStream(output);
		Serialize.write(packedOutputStream, message);
	}
	
	static void writeToUnbuffered(WritableByteChannel output, MessageBuilder message)
	{
		auto buffered = new BufferedOutputStreamWrapper(output);
		write(buffered, message);
		buffered.flush();
	}
}
