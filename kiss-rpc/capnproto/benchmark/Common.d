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

module capnproto.benchmark.Common;

//Use a 128-bit Xorshift algorithm.
pragma(inline, true) uint nextFastRand()
{
	//These values are arbitrary. Any seed other than all zeroes is OK.
	static uint x = 0x1d2acd47;
	static uint y = 0x58ca3e14;
	static uint z = 0xf563f232;
	static uint w = 0x0bc76199;
	
	uint tmp = x ^ (x << 11);
	x = y;
	y = z;
	z = w;
	w = w ^ (w >> 19) ^ tmp ^ (tmp >> 8);
	return w;
}

pragma(inline, true) uint fastRand(uint range)
{
	return nextFastRand() % range;
}

pragma(inline, true) double fastRandDouble(double range)
{
	return nextFastRand() * range / uint.max;
}

pragma(inline, true) int div(int a, int b)
{
	if(b == 0)
		return int.max;
	// INT_MIN / -1 => SIGFPE.  Who knew?
	if(a == int.min && b == -1)
		return int.max;
	return a / b;
}

pragma(inline, true) int mod(int a, int b)
{
	if(b == 0)
		return int.max;
	//INT_MIN % -1 => SIGFPE. Who knew?
	if(a == int.min && b == -1)
		return int.max;
	return a % b;
}

string[] WORDS = [ "foo ", "bar ", "baz ", "qux ", "quux ", "corge ", "grault ", "garply ", "waldo ", "fred ", "plugh ", "xyzzy ", "thud " ];
