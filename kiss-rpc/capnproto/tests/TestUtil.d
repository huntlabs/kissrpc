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

module capnproto.tests.TestUtil;

import capnproto;

import capnproto.tests.test;
import capnproto.tests.testimport;

struct TestUtil
{
	static ubyte[] data(string str)
	{
		return cast(ubyte[])str;
	}
	
	static void initTestMessage(TestAllTypes.Builder builder)
	{
		builder.setVoidField();
		builder.setBoolField(true);
		builder.setInt8Field(-123);
		builder.setInt16Field(-12345);
		builder.setInt32Field(-12345678);
		builder.setInt64Field(-123456789012345L);
		builder.setUInt8Field(0xea);
		builder.setUInt16Field(0x4567);
		builder.setUInt32Field(0x34567890);
		builder.setUInt64Field(0x1234567890123456L);
		builder.setFloat32Field(1234.5f);
		builder.setFloat64Field(-123e45);
		builder.setTextField("foo");
		builder.setDataField(data("bar"));
		
		{
			auto subBuilder = builder.initStructField();
			subBuilder.setVoidField();
			subBuilder.setBoolField(true);
			subBuilder.setInt8Field(-12);
			subBuilder.setInt16Field(3456);
			subBuilder.setInt32Field(-78901234);
			subBuilder.setInt64Field(56789012345678L);
			subBuilder.setUInt8Field(90);
			subBuilder.setUInt16Field(1234);
			subBuilder.setUInt32Field(56789012);
			subBuilder.setUInt64Field(345678901234567890L);
			subBuilder.setFloat32Field(-1.25e-10f);
			subBuilder.setFloat64Field(345);
			subBuilder.setTextField(Text.Reader("baz"));
			subBuilder.setDataField(data("qux"));
			
			{
				auto subSubBuilder = subBuilder.initStructField();
				subSubBuilder.setTextField(Text.Reader("nested"));
				subSubBuilder.initStructField().setTextField(Text.Reader("really nested"));
			}
			
			subBuilder.setEnumField(TestEnum.baz);
			
			auto boolList = subBuilder.initBoolList(5);
			boolList.set(0, false);
			boolList.set(1, true);
			boolList.set(2, false);
			boolList.set(3, true);
			boolList.set(4, true);
		}
		
		builder.setEnumField(TestEnum.corge);
		builder.initVoidList(6);
		
		auto boolList = builder.initBoolList(4);
		boolList.set(0, true);
		boolList.set(1, false);
		boolList.set(2, false);
		boolList.set(3, true);
		
		auto float64List = builder.initFloat64List(4);
		float64List.set(0, 7777.75);
		float64List.set(1, double.infinity);
		float64List.set(2, -double.infinity);
		float64List.set(3, double.nan);
		
		auto textList = builder.initTextList(3);
		textList.set(0, Text.Reader("plugh"));
		textList.set(1, Text.Reader("xyzzy"));
		textList.set(2, Text.Reader("thud"));
		
		auto structList = builder.initStructList(3);
		structList.get(0).setTextField(Text.Reader("structlist 1"));
		structList.get(1).setTextField(Text.Reader("structlist 2"));
		structList.get(2).setTextField(Text.Reader("structlist 3"));
		
		auto enumList = builder.initEnumList(2);
		enumList.set(0, TestEnum.foo);
		enumList.set(1, TestEnum.garply);
	}
	
	static void checkTestMessage(TestAllTypes.Builder builder)
	{
		builder.getVoidField();
		assert(builder.getBoolField() == true);
		assert(builder.getInt8Field() == -123);
		assert(builder.getInt16Field() == -12345);
		assert(builder.getInt32Field() == -12345678);
		assert(builder.getInt64Field() == -123456789012345L);
		assert(builder.getUInt8Field() == 0xea);
		assert(builder.getUInt16Field() == 0x4567);
		assert(builder.getUInt32Field() == 0x34567890);
		assert(builder.getUInt64Field() == 0x1234567890123456L);
		assert(builder.getFloat32Field() == 1234.5f);
		assert(builder.getFloat64Field() == -123e45);
		assert(builder.getTextField().toString() == "foo");
		
		{
			auto subBuilder = builder.getStructField();
			subBuilder.getVoidField();
			assert(subBuilder.getBoolField() == true);
			assert(subBuilder.getInt8Field() == -12);
			assert(subBuilder.getInt16Field() == 3456);
			assert(subBuilder.getInt32Field() == -78901234);
			assert(subBuilder.getInt64Field() == 56789012345678L);
			assert(subBuilder.getUInt8Field() == 90);
			assert(subBuilder.getUInt16Field() == 1234);
			assert(subBuilder.getUInt32Field() == 56789012);
			assert(subBuilder.getUInt64Field() == 345678901234567890L);
			assert(subBuilder.getFloat32Field() == -1.25e-10f);
			assert(subBuilder.getFloat64Field() == 345);
			
			{
				auto subSubBuilder = subBuilder.getStructField();
				assert(subSubBuilder.getTextField().toString() == "nested");
			}
			
			assert(subBuilder.getEnumField() == TestEnum.baz);
			
			auto boolList = subBuilder.getBoolList();
			assert(boolList.get(0) == false);
			assert(boolList.get(1) == true);
			assert(boolList.get(2) == false);
			assert(boolList.get(3) == true);
			assert(boolList.get(4) == true);
		}
		assert(builder.getEnumField() == TestEnum.corge);
		
		assert(builder.getVoidList().length == 6);
		
		auto boolList = builder.getBoolList();
		assert(boolList.get(0) == true);
		assert(boolList.get(1) == false);
		assert(boolList.get(2) == false);
		assert(boolList.get(3) == true);
		
		auto float64List = builder.getFloat64List();
		assert(float64List.get(0) == 7777.75);
		assert(float64List.get(1) == double.infinity);
		assert(float64List.get(2) == -double.infinity);
		assert(float64List.get(3) != float64List.get(3)); // NaN;
		
		auto textList = builder.getTextList();
		assert(textList.length == 3);
		assert(textList.get(0).toString() == "plugh");
		assert(textList.get(1).toString() == "xyzzy");
		assert(textList.get(2).toString() == "thud");
		
		auto structList = builder.getStructList();
		assert(structList.length == 3);
		assert(structList.get(0).getTextField().toString() == "structlist 1");
		assert(structList.get(1).getTextField().toString() == "structlist 2");
		assert(structList.get(2).getTextField().toString() == "structlist 3");
		
		auto enumList = builder.getEnumList();
		assert(enumList.get(0) == TestEnum.foo);
		assert(enumList.get(1) == TestEnum.garply);
	};
	
	static void checkTestMessage(TestAllTypes.Reader reader)
	{
		reader.getVoidField();
		assert(reader.getBoolField() == true);
		assert(reader.getInt8Field() == -123);
		assert(reader.getInt16Field() == -12345);
		assert(reader.getInt32Field() == -12345678);
		assert(reader.getInt64Field() == -123456789012345L);
		assert(reader.getUInt8Field() == 0xea);
		assert(reader.getUInt16Field() == 0x4567);
		assert(reader.getUInt32Field() == 0x34567890);
		assert(reader.getUInt64Field() == 0x1234567890123456L);
		assert(reader.getFloat32Field() == 1234.5f);
		assert(reader.getFloat64Field() == -123e45);
		assert(reader.getTextField() == "foo");
		
		{
			auto subReader = reader.getStructField();
			subReader.getVoidField();
			assert(subReader.getBoolField() == true);
			assert(subReader.getInt8Field() == -12);
			assert(subReader.getInt16Field() == 3456);
			assert(subReader.getInt32Field() == -78901234);
			assert(subReader.getInt64Field() == 56789012345678L);
			assert(subReader.getUInt8Field() == 90);
			assert(subReader.getUInt16Field() == 1234);
			assert(subReader.getUInt32Field() == 56789012);
			assert(subReader.getUInt64Field() == 345678901234567890L);
			assert(subReader.getFloat32Field() == -1.25e-10f);
			assert(subReader.getFloat64Field() == 345);
			
			{
				auto subSubReader = subReader.getStructField();
				assert(subSubReader.getTextField() == "nested");
			}
			auto boolList = subReader.getBoolList();
			assert(boolList.get(0) == false);
			assert(boolList.get(1) == true);
			assert(boolList.get(2) == false);
			assert(boolList.get(3) == true);
			assert(boolList.get(4) == true);
		}
		
		assert(reader.getVoidList().length == 6);
		
		auto boolList = reader.getBoolList();
		assert(boolList.get(0) == true);
		assert(boolList.get(1) == false);
		assert(boolList.get(2) == false);
		assert(boolList.get(3) == true);
		
		auto float64List = reader.getFloat64List();
		assert(float64List.get(0) == 7777.75);
		assert(float64List.get(1) == double.infinity);
		assert(float64List.get(2) == -double.infinity);
		assert(float64List.get(3) != float64List.get(3)); // NaN;
		
		auto textList = reader.getTextList();
		assert(textList.length == 3);
		assert(textList.get(0) == "plugh");
		assert(textList.get(1) == "xyzzy");
		assert(textList.get(2) == "thud");
		
		auto structList = reader.getStructList();
		assert(3 == structList.length);
		assert(structList.get(0).getTextField() == "structlist 1");
		assert(structList.get(1).getTextField() == "structlist 2");
		assert(structList.get(2).getTextField() == "structlist 3");
		
		auto enumList = reader.getEnumList();
		assert(enumList.get(0) == TestEnum.foo);
		assert(enumList.get(1) == TestEnum.garply);
	};
	
	static void checkDefaultMessage(TestDefaults.Builder builder)
	{
		builder.getVoidField();
		assert(builder.getBoolField() == true);
		assert(builder.getInt8Field() == -123);
		assert(builder.getInt16Field() == -12345);
		assert(builder.getInt32Field() == -12345678);
		assert(builder.getInt64Field() == -123456789012345L);
		assert(builder.getUInt8Field() == 0xea);
		assert(builder.getUInt16Field() == 45678);
		assert(builder.getUInt32Field() == 0xce0a6a14);
		assert(builder.getUInt64Field() == 0xab54a98ceb1f0ad2L);
		assert(builder.getFloat32Field() == 1234.5f);
		assert(builder.getFloat64Field() == -123e45);
		assert(builder.getEnumField() == TestEnum.corge);
		
		assert(builder.getTextField().toString() == "foo");
		assert(builder.getDataField().toArray() == [0x62, 0x61, 0x72]);
	}
	
	static void checkDefaultMessage(TestDefaults.Reader reader)
	{
		reader.getVoidField();
		assert(reader.getBoolField() == true);
		assert(reader.getInt8Field() == -123);
		assert(reader.getInt16Field() == -12345);
		assert(reader.getInt32Field() == -12345678);
		assert(reader.getInt64Field() == -123456789012345L);
		assert(reader.getUInt8Field() == 0xea);
		assert(reader.getUInt16Field() == 45678);
		assert(reader.getUInt32Field() == 0xce0a6a14);
		assert(reader.getUInt64Field() == 0xab54a98ceb1f0ad2L);
		assert(reader.getFloat32Field() == 1234.5f);
		assert(reader.getFloat64Field() == -123e45);
		assert(reader.getTextField() == "foo");
		assert(reader.getDataField() == [0x62, 0x61, 0x72]);
		
		{
			auto subReader = reader.getStructField();
			subReader.getVoidField();
			assert(subReader.getBoolField() == true);
			assert(subReader.getInt8Field() == -12);
			assert(subReader.getInt16Field() == 3456);
			assert(subReader.getInt32Field() == -78901234);
			assert(subReader.getTextField() == "baz");
			
			{
				auto subSubReader = subReader.getStructField();
				assert(subSubReader.getTextField() == "nested");
			}
		}
		
		assert(reader.getEnumField() == TestEnum.corge);
		
		assert(reader.getVoidList().length == 6);
		
		{
			auto listReader = reader.getBoolList();
			assert(listReader.length == 4);
			assert(listReader.get(0) == true);
			assert(listReader.get(1) == false);
			assert(listReader.get(2) == false);
			assert(listReader.get(3) == true);
		}
		
		{
			auto listReader = reader.getInt8List();
			assert(listReader.length == 2);
			assert(listReader.get(0) == 111);
			assert(listReader.get(1) == -111);
		}
	}
	
	static void setDefaultMessage(TestDefaults.Builder builder)
	{
		builder.setBoolField(false);
		builder.setInt8Field(-122);
		builder.setInt16Field(-12344);
		builder.setInt32Field(-12345677);
		builder.setInt64Field(-123456789012344L);
		builder.setUInt8Field(0xe9);
		builder.setUInt16Field(45677);
		builder.setUInt32Field(0xce0a6a13);
		builder.setUInt64Field(0xab54a98ceb1f0ad1L);
		builder.setFloat32Field(1234.4f);
		builder.setFloat64Field(-123e44);
		builder.setTextField(Text.Reader("bar"));
		builder.setEnumField(TestEnum.qux);
	}
	
	static void checkSettedDefaultMessage(TestDefaults.Reader reader)
	{
		assert(reader.getBoolField() == false);
		assert(reader.getInt8Field() == -122);
		assert(reader.getInt16Field() == -12344);
		assert(reader.getInt32Field() == -12345677);
		assert(reader.getInt64Field() == -123456789012344L);
		assert(reader.getUInt8Field() == 0xe9);
		assert(reader.getUInt16Field() == 45677);
		assert(reader.getUInt32Field() == 0xce0a6a13);
		assert(reader.getUInt64Field() == 0xab54a98ceb1f0ad1L);
		assert(reader.getFloat32Field() == 1234.4f);
		assert(reader.getFloat64Field() == -123e44);
		assert(reader.getEnumField() == TestEnum.qux);
	}
}
