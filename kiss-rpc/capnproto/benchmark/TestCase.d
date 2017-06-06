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

module capnproto.benchmark.TestCase;

import std.conv : to;
import std.stdio;

import java.io.IOException;
import java.nio.ByteBuffer;

import capnproto.ArrayInputStream;
import capnproto.ArrayOutputStream;
import capnproto.BufferedInputStreamWrapper;
import capnproto.BufferedOutputStreamWrapper;
import capnproto.FileDescriptor;
import capnproto.MessageBuilder;
import capnproto.MessageReader;

import capnproto.benchmark.Common;
import capnproto.benchmark.Compression;

abstract class TestCase(Request, Response, Expectation)
{
public: //Variables.
	enum SCRATCH_SIZE = 128 * 1024;

public: //Methods.
	abstract Expectation setupRequest(Request.Builder request);
	abstract void handleRequest(Request.Reader request, Response.Builder response);
	abstract bool checkResponse(Response.Reader response, Expectation expected);
	
	void passByObject(Compression compression, long iters)
	{
		foreach(ii; 0..iters)
		{
			auto requestMessage = new MessageBuilder();
			auto responseMessage = new MessageBuilder();
			auto request = requestMessage.initRoot!Request;
			auto expected = this.setupRequest(request);
			auto response = responseMessage.initRoot!Response;
			this.handleRequest(request.asReader(), response);
			if(!this.checkResponse(response.asReader(), expected))
				writeln("Mismatch!");
		}
	}
	
	void passByBytes(Compression compression, long iters)
	{
		auto requestBytes = ByteBuffer(new ubyte[](SCRATCH_SIZE * 8));
		auto responseBytes = ByteBuffer(new ubyte[](SCRATCH_SIZE * 8));
		
		foreach(ii; 0..iters)
		{
			auto requestMessage = new MessageBuilder();
			auto responseMessage = new MessageBuilder();
			auto request = requestMessage.initRoot!Request;
			auto expected = this.setupRequest(request);
			auto response = responseMessage.initRoot!Response;
			
			{
				auto writer = new ArrayOutputStream(requestBytes);
				compression.writeBuffered(writer, requestMessage);
			}
			
			{
				auto messageReader = compression.newBufferedReader(new ArrayInputStream(requestBytes));
				this.handleRequest(messageReader.getRoot!Request, response);
			}
			
			{
				auto writer = new ArrayOutputStream(responseBytes);
				compression.writeBuffered(writer, responseMessage);
			}
			
			{
				auto messageReader = compression.newBufferedReader(new ArrayInputStream(responseBytes));
				if(!this.checkResponse(messageReader.getRoot!Response, expected))
					throw new Error("Incorrect response!");
			}
		}
	}
	
	void syncServer(Compression compression, long iters)
	{
		auto outBuffered = new BufferedOutputStreamWrapper(new FileDescriptor(stdout));
		auto inBuffered = new BufferedInputStreamWrapper(new FileDescriptor(stdin));
		
		foreach(ii; 0..iters)
		{
			auto responseMessage = new MessageBuilder();
			{
				auto response = responseMessage.initRoot!Response;
				auto messageReader = compression.newBufferedReader(inBuffered);
				auto request = messageReader.getRoot!Request;
				this.handleRequest(request, response);
			}
			compression.writeBuffered(outBuffered, responseMessage);
		}
	}
	
	void syncClient(Compression compression, long iters)
	{
		auto outBuffered = new BufferedOutputStreamWrapper(new FileDescriptor(stdout));
		auto inBuffered = new BufferedInputStreamWrapper(new FileDescriptor(stdin));
		
		foreach(ii; 0..iters)
		{
			auto requestMessage = new MessageBuilder();
			auto request = requestMessage.initRoot!Request;
			auto expected = this.setupRequest(request);
			
			compression.writeBuffered(outBuffered, requestMessage);
			auto messageReader = compression.newBufferedReader(inBuffered);
			auto response = messageReader.getRoot!Response;
			if(!this.checkResponse(response, expected))
				throw new Error("Incorrect response!");
		}
	}
	
	void execute(string[] args)
	{
		if(args.length != 5)
		{
			writeln("USAGE: TestCase MODE REUSE COMPRESSION ITERATION_COUNT");
			return;
		}
		
		auto mode = args[1];
		auto reuse = args[2];
		Compression compression;
		if(args[3] == "packed")
			compression = cast(Compression)Compression.packed;
		else if(args[3] == "none")
			compression = cast(Compression)Compression.uncompressed;
		else
			throw new Error("Unrecognized compression: " ~ args[2]);
		
		long iters = to!long(args[4]);
		
		if(mode == "object")
			passByObject(compression, iters);
		else if(mode == "bytes")
			passByBytes(compression, iters);
		else if(mode == "client")
			syncClient(compression, iters);
		else if(mode == "server")
			syncServer(compression, iters);
		else
			writefln("Unrecognized mode: %s", mode);
	}
}
