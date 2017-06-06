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

module capnproto.tests.EncodingSuite;

import java.nio.ByteBuffer;

import capnproto;

import capnproto.tests.test;
import capnproto.tests.testimport;
import capnproto.tests.TestUtil;

//AllTypes
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	TestUtil.initTestMessage(allTypes);
	TestUtil.checkTestMessage(allTypes);
	TestUtil.checkTestMessage(allTypes.asReader());
}

//AllTypesMultiSegment
unittest
{
	auto message = new MessageBuilder(5, BuilderArena.AllocationStrategy.FIXED_SIZE);
	auto allTypes = message.initRoot!TestAllTypes();
	TestUtil.initTestMessage(allTypes);
	
	TestUtil.checkTestMessage(allTypes);
	TestUtil.checkTestMessage(allTypes.asReader());
}

//Setters
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	TestUtil.initTestMessage(allTypes);
	
	auto message2 = new MessageBuilder();
	auto allTypes2 = message2.initRoot!TestAllTypes();
	
	allTypes2.setStructField(allTypes.asReader());
	TestUtil.checkTestMessage(allTypes2.getStructField());
	auto reader = allTypes2.asReader().getStructField();
	TestUtil.checkTestMessage(reader);
}

//Zeroing
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	
	auto structList = allTypes.initStructList(3);
	TestUtil.initTestMessage(structList.get(0));
	
	auto structField = allTypes.initStructField();
	TestUtil.initTestMessage(structField);
	
	TestUtil.initTestMessage(structList.get(1));
	TestUtil.initTestMessage(structList.get(2));
	TestUtil.checkTestMessage(structList.get(0));
	allTypes.initStructList(0);
	
	TestUtil.checkTestMessage(allTypes.getStructField());
	auto allTypesReader = allTypes.asReader();
	TestUtil.checkTestMessage(allTypesReader.getStructField());
	
	auto any = message.initRoot!AnyPointer();
	auto segments = message.getSegmentsForOutput();
	foreach(segment; segments)
	{
		foreach(jj; 0..segment.limit - 1)
			assert(segment.get!ubyte(jj) == 0);
	}
}

//DoubleFarPointers
unittest
{
	ubyte[] bytes = [2,0,0,0, 1,0,0,0, 2,0,  0,  0, 1,0,0,0,
	                 6,0,0,0, 1,0,0,0, 2,0,  0,  0, 2,0,0,0,
	                 0,0,0,0, 1,0,0,0, 1,7,255,127, 0,0,0,0];
	
	auto input = new ArrayInputStream(ByteBuffer(bytes));
	auto message = Serialize.read(input);
	auto root = message.getRoot!TestAllTypes();
	assert(root.getBoolField() == true);
	assert(root.getInt8Field() == 7);
	assert(root.getInt16Field() == 32767);
}

//UpgradeStructInBuilder
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestAnyPointer();
	
	{
		auto oldVersion = root.getAnyPointerField().initAs!TestOldVersion();
		oldVersion.setOld1(123);
		oldVersion.setOld2("foo");
		auto sub = oldVersion.initOld3();
		sub.setOld1(456);
		sub.setOld2("bar");
	}
	
	{
		auto newVersion = root.getAnyPointerField().getAs!TestNewVersion();
		assert(newVersion.getOld1() == 123);
		assert(newVersion.getOld2().toString() == "foo");
		assert(newVersion.getNew1() == 987);
		assert(newVersion.getNew2().toString() == "baz");
		
		auto sub = newVersion.getOld3();
		assert(sub.getOld1() == 456);
		assert(sub.getOld2().toString() == "bar");
		
		newVersion.setOld1(234);
		newVersion.setOld2("qux");
		newVersion.setNew1(654);
		newVersion.setNew2("quux");
	}
	
	{
		auto oldVersion = root.getAnyPointerField().getAs!TestOldVersion();
		assert(oldVersion.getOld1() == 234);
		assert(oldVersion.getOld2.toString() == "qux");
	}
}

//StructListUpgrade
unittest
{
	auto message = new MessageBuilder();
	auto root = message.initRoot!TestAnyPointer();
	auto any = root.getAnyPointerField();
	
	{
		auto longs = any.initAs!(PrimitiveList!long)(3);
		longs.set(0, 123);
		longs.set(1, 456);
		longs.set(2, 789);
	}
	
	{
		auto olds = any.asReader().getAs!(StructList!TestOldVersion)();
		assert(olds.get(0).getOld1() == 123);
		assert(olds.get(1).getOld1() == 456);
		assert(olds.get(2).getOld1() == 789);
	}
	
	{
		auto olds = any.getAs!(StructList!TestOldVersion)();
		assert(olds.length == 3);
		assert(olds.get(0).getOld1() == 123);
		assert(olds.get(1).getOld1() == 456);
		assert(olds.get(2).getOld1() == 789);
		
		olds.get(0).setOld2("zero");
		olds.get(1).setOld2("one");
		olds.get(2).setOld2("two");
	}
	
	{
		auto news = any.getAs!(StructList!TestNewVersion)();
		assert(news.length == 3);
		assert(news.get(0).getOld1() == 123);
		assert(news.get(0).getOld2().toString() == "zero");
		
		assert(news.get(1).getOld1() == 456);
		assert(news.get(1).getOld2().toString() == "one");
		
		assert(news.get(2).getOld1() == 789);
		assert(news.get(2).getOld2().toString() == "two");
	}
}

//StructListUpgradeDoubleFar
unittest
{
	ubyte[] bytes = [
	           1, 0, 0, 0, 0x1f, 0, 0, 0, //List, inline composite, 3 words.
	           4, 0, 0, 0,    1, 0, 2, 0, //Struct tag. 1 element, 1 word data, 2 pointers.
	          91, 0, 0, 0,    0, 0, 0, 0, //Data: 91.
	        0x05, 0, 0, 0, 0x42, 0, 0, 0, //List pointer, offset 1, type = BYTE, length 8.
	           0, 0, 0, 0,    0, 0, 0, 0, //Null pointer.
	        0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x21, 0x21, 0]; //"hello!!".
	
	auto segment = ByteBuffer(bytes);
	auto messageReader = new MessageReader([segment], ReaderOptions.DEFAULT_READER_OPTIONS);
	
	auto oldVersion = messageReader.getRoot!(StructList!TestOldVersion)();
	
	assert(oldVersion.length == 1);
	assert(oldVersion.get(0).getOld1() == 91);
	assert(oldVersion.get(0).getOld2() == "hello!!");
	
	//Make the first segment exactly large enough to fit the original message.
	//This leaves no room for a far pointer landing pad in the first segment.
	auto message = new MessageBuilder(6);
	message.setRoot!TestOldVersion(oldVersion);
	
	auto segments = message.getSegmentsForOutput();
	assert(segments.length == 1);
	assert(segments[0].limit == 6 * 8);
	
	auto newVersion = message.getRoot!(StructList!TestNewVersion)();
	assert(newVersion.length == 1);
	assert(newVersion.get(0).getOld1() == 91);
	assert(newVersion.get(0).getOld2().toString() == "hello!!");
	
	auto segments1 = message.getSegmentsForOutput();
	assert(segments[0].limit == 6 * 8);
	//Check the the old list, including the tag, was zeroed.
	foreach(ii; 8..(5 * 8) - 1)
		assert(segments[0].get!ubyte(ii) == 0);
}

//Generics
unittest
{
	auto message = new MessageBuilder();
	auto root = message.initRoot!(TestGenerics!(TestAllTypes, Text))();
	TestUtil.initTestMessage(root.getFoo());
	root.getDub().setFoo(Text.Reader("Hello"));
	auto bar = root.getDub().initBar(1);
	bar.set(0, 11);
	auto revBar = root.getRev().getBar();
	revBar.setInt8Field(111);
	auto boolList = revBar.initBoolList(2);
	boolList.set(0, false);
	boolList.set(1, true);
	
	TestUtil.checkTestMessage(root.getFoo());
	auto rootReader = root.asReader();
	TestUtil.checkTestMessage(rootReader.getFoo());
	auto dubReader = root.getDub();
	assert(dubReader.getFoo().toString() == "Hello");
	auto barReader = dubReader.getBar();
	assert(barReader.length == 1);
	assert(barReader.get(0) == 11);
}

//UseGenerics
unittest
{
	auto message = new MessageBuilder();
	auto root = message.initRoot!TestUseGenerics();
	
	{
		auto message2 = new MessageBuilder();
		auto root2 = message2.initRoot!(TestGenerics!(AnyPointer, AnyPointer))();
		root2.initDub().setFoo(Text.Reader("foobar"));
		
		root.setUnspecified(root2.asReader());
	}
	
	auto rootReader = root.asReader();
	assert(root.getUnspecified().getDub().getFoo().toString() == "foobar");
}

//Defaults
unittest
{
	auto message = new MessageBuilder();
	auto defaults = message.initRoot!TestDefaults();
	TestUtil.checkDefaultMessage(defaults);
	TestUtil.checkDefaultMessage(defaults.asReader());
	TestUtil.setDefaultMessage(defaults);
	TestUtil.checkSettedDefaultMessage(defaults.asReader());
}

//Unions
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestUnion();
	auto u0 = root.initUnion0();
	u0.initU0f1sp(10);
	assert(u0.which() == TestUnion.Union0.Which.u0f1sp);
	
	u0.initPrimitiveList(10);
	assert(u0.which() == TestUnion.Union0.Which.primitiveList);
}

//Groups
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestGroups();
	
	{
		auto foo = root.getGroups().initFoo();
		foo.setCorge(12345678);
		foo.setGrault(123456789012345L);
		foo.setGarply(Text.Reader("foobar"));
		
		assert(foo.getCorge() == 12345678);
		assert(foo.getGrault() == 123456789012345L);
		assert(foo.getGarply().toString() == "foobar");
	}
	
	{
		auto bar = root.getGroups.initBar();
		bar.setCorge(23456789);
		bar.setGrault(Text.Reader("barbaz"));
		bar.setGarply(234567890123456L);
		
		assert(bar.getCorge() == 23456789);
		assert(bar.getGrault().toString() == "barbaz");
		assert(bar.getGarply() == 234567890123456L);
	}
	
	{
		auto baz = root.getGroups().initBaz();
		baz.setCorge(34567890);
		baz.setGrault(Text.Reader("bazqux"));
		baz.setGarply(Text.Reader("quxquux"));
		
		assert(baz.getCorge() == 34567890);
		assert(baz.getGrault().toString() == "bazqux");
		assert(baz.getGarply().toString() == "quxquux");
	}
}


//NestedLists
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestLists();
	
	{
		auto intListList = root.initInt32ListList(2);
		auto intList0 = intListList.init(0, 4);
		intList0.set(0, 1);
		intList0.set(1, 2);
		intList0.set(2, 3);
		intList0.set(3, 4);
		auto intList1 = intListList.init(1, 1);
		intList1.set(0, 100);
	}
	
	{
		auto reader = root.asReader();
		auto intListList = root.getInt32ListList();
		assert(intListList.length == 2);
		auto intList0 = intListList.get(0);
		assert(intList0.length == 4);
		assert(intList0.get(0) == 1);
		assert(intList0.get(1) == 2);
		assert(intList0.get(2) == 3);
		assert(intList0.get(3) == 4);
		auto intList1 = intListList.get(1);
		assert(intList1.length == 1);
		assert(intList1.get(0) == 100);
	}
}

//Constants
unittest
{
	assert(TestConstants.voidConst == Void.VOID);
	assert(TestConstants.boolConst == true);
	assert(TestConstants.int8Const == -123);
	assert(TestConstants.int16Const == -12345);
	assert(TestConstants.int32Const == -12345678);
	assert(TestConstants.int64Const == -123456789012345L);
	
	assert(TestConstants.uint8Const == cast(ubyte)-22);
	assert(TestConstants.uint16Const == cast(ushort)-19858);
	assert(TestConstants.uint32Const == cast(uint)-838178284);
	assert(TestConstants.uint64Const == cast(ulong)-6101065172474983726L);
	
	assert(TestConstants.float32Const == 1234.5f);
	assert(TestConstants.float64Const == -123e45);
	
	assert(TestConstants.textConst.get().toString() == "foo");
	assert(TestConstants.dataConst.get().toArray() == TestUtil.data("bar"));
	
	assert(TestConstants.enumConst == TestEnum.corge);
	
	{
		auto subReader = TestConstants.structConst.get();
		assert(subReader.getBoolField() == true);
		assert(subReader.getInt8Field() == -12);
		assert(subReader.getInt16Field() == 3456);
		assert(subReader.getInt32Field() == -78901234);
		assert(subReader.getInt64Field() == 56789012345678L);
		assert(subReader.getUInt8Field() == 90);
		assert(subReader.getUInt16Field == 1234);
		assert(subReader.getUInt32Field() == 56789012);
		assert(subReader.getUInt64Field() == 345678901234567890L);
		assert(subReader.getFloat32Field() == -1.25e-10f);
		assert(subReader.getFloat64Field() == 345);
		assert(subReader.getTextField() == "baz");
	}
	
	assert(TestConstants.voidListConst.get().length == 6);
	
	{
		auto listReader = TestConstants.boolListConst.get();
		assert(listReader.length == 4);
		assert(listReader.get(0) == true);
		assert(listReader.get(1) == false);
		assert(listReader.get(2) == false);
		assert(listReader.get(3) == true);
	}
	
	{
		auto listReader = TestConstants.textListConst.get();
		assert(listReader.length == 3);
		assert(listReader.get(0) == "plugh");
		assert(listReader.get(1) == "xyzzy");
		assert(listReader.get(2) == "thud");
	}
	
	{
		auto listReader = TestConstants.structListConst.get();
		assert(listReader.length == 3);
		assert(listReader.get(0).getTextField() == "structlist 1");
		assert(listReader.get(1).getTextField() == "structlist 2");
		assert(listReader.get(2).getTextField() == "structlist 3");
	}
}

//GlobalConstants
unittest
{
	assert(globalInt == 12345);
}

//EmptyStruct
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestAnyPointer();
	assert(root.hasAnyPointerField() == false);
	auto any = root.getAnyPointerField();
	assert(any.isNull() == true);
	any.initAs!TestEmptyStruct();
	assert(any.isNull() == false);
	assert(root.hasAnyPointerField() == true);
	
	{
		auto rootReader = root.asReader();
		assert(rootReader.hasAnyPointerField() == true);
		assert(rootReader.getAnyPointerField().isNull() == false);
	}
}

//TextBuilderIntUnderflow
unittest
{
	import std.exception : assertThrown;
	auto message = new MessageBuilder();
	auto root = message.initRoot!TestAnyPointer();
	root.getAnyPointerField.initAs!Data(0);
	assertThrown!DecodeException(root.getAnyPointerField.getAs!Text());
}

//InlineCompositeListIntOverflow
unittest
{
	import std.exception : assertThrown;
	ubyte[] bytes = [0,0,0,0,    0,0,1,0,
	                 1,0,0,0, 0x17,0,0,0, 0,0,0,0xff, 16,0,0,0,
	                 0,0,0,0,    0,0,0,0, 0,0,0,   0,  0,0,0,0];
	
	auto segment = ByteBuffer(bytes);
	auto message = new MessageReader([segment], ReaderOptions.DEFAULT_READER_OPTIONS);
	
	auto root = message.getRoot!TestAnyPointer();
	//TODO: Add this after we implement totalSize():
	//root.totalSize();
	
	assertThrown!DecodeException(root.getAnyPointerField.getAs!(StructList!TestAllTypes)());
	
	auto messageBuilder = new MessageBuilder();
	auto builderRoot = messageBuilder.initRoot!TestAnyPointer();
	assertThrown!DecodeException(builderRoot.getAnyPointerField.setAs!TestAnyPointer(root));
}

//VoidListAmplification
unittest
{
	import std.exception : assertThrown;
	auto builder = new MessageBuilder();
	builder.initRoot!TestAnyPointer().getAnyPointerField().initAs!(PrimitiveList!Void)(1 << 28);
	
	auto segments = builder.getSegmentsForOutput();
	assert(segments.length == 1);
	
	auto reader = new MessageReader(segments, ReaderOptions.DEFAULT_READER_OPTIONS);
	auto root = reader.getRoot!TestAnyPointer();
	assertThrown!DecodeException(root.getAnyPointerField().getAs!(StructList!TestAllTypes)());
}

//EmptyStructListAmplification
unittest
{
	import std.exception : assertThrown;
	auto builder = new MessageBuilder();
	builder.initRoot!TestAnyPointer().getAnyPointerField().initAs!(StructList!TestEmptyStruct)((1 << 29) - 1);
	
	auto segments = builder.getSegmentsForOutput();
	assert(segments.length == 1);
	
	auto reader = new MessageReader(segments, ReaderOptions.DEFAULT_READER_OPTIONS);
	auto root = reader.getRoot!TestAnyPointer();
	assertThrown!DecodeException(root.getAnyPointerField().getAs!(StructList!TestAllTypes)());
}

//LongUint8List
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 28) + 1;
	auto list = allTypes.initUInt8List(length);
	assert(list.length == length);
	list.set(length - 1, 3);
	assert(list.get(length - 1) == 3);
	assert(allTypes.asReader().getUInt8List().get(length - 1) == 3);
}


//LongUint16List
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 27) + 1;
	auto list = allTypes.initUInt16List(length);
	assert(list.length == length);
	list.set(length - 1, 3);
	assert(list.get(length - 1) == 3);
	assert(allTypes.asReader().getUInt16List().get(length - 1) == 3);
}

//LongUint32List
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 26) + 1;
	auto list = allTypes.initUInt32List(length);
	assert(list.length == length);
	list.set(length - 1, 3);
	assert(list.get(length - 1) == 3);
	assert(allTypes.asReader().getUInt32List().get(length - 1) == 3);
}

//LongUint64List
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 25) + 1;
	auto list = allTypes.initUInt64List(length);
	assert(list.length == length);
	list.set(length - 1, 3);
	assert(list.get(length - 1) == 3);
	assert(allTypes.asReader().getUInt64List().get(length - 1) == 3);
}

//LongFloat32List
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 26) + 1;
	auto list = allTypes.initFloat32List(length);
	assert(list.length == length);
	list.set(length - 1, 3.14f);
	assert(list.get(length - 1) == 3.14f);
	assert(allTypes.asReader().getFloat32List().get(length - 1) == 3.14f);
}

//LongFloat64List
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 25) + 1;
	auto list = allTypes.initFloat64List(length);
	assert(list.length == length);
	list.set(length - 1, 3.14);
	assert(list.get(length - 1) == 3.14);
	assert(allTypes.asReader().getFloat64List().get(length - 1) == 3.14);
}

//LongStructList
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 21) + 1;
	auto list = allTypes.initStructList(length);
	assert(list.length == length);
	list.get(length - 1).setUInt8Field(3);
	assert(allTypes.asReader().getStructList().get(length - 1).getUInt8Field() == 3);
}

//LongTextList
unittest
{
	auto message = new MessageBuilder();
	auto allTypes = message.initRoot!TestAllTypes();
	auto length = (1 << 25) + 1;
	auto list = allTypes.initTextList(length);
	assert(list.length == length);
	list.set(length - 1, Text.Reader("foo"));
	assert(allTypes.asReader().getTextList().get(length - 1) == "foo");
}

//LongListList
unittest
{
	auto message = new MessageBuilder();
	auto root = message.initRoot!TestLists();
	auto length = (1 << 25) + 1;
	auto list = root.initStructListList(length);
	assert(list.length == length);
	list.init(length - 1, 3);
	assert(list.get(length - 1).length == 3);
	assert(root.asReader().getStructListList().get(length - 1).length == 3);
}

//StructSetters
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestAllTypes();
	TestUtil.initTestMessage(root);
	
	{
		auto builder2 = new MessageBuilder();
		builder2.setRoot!TestAllTypes(root.asReader());
		TestUtil.checkTestMessage(builder2.getRoot!TestAllTypes());
	}
	
	{
		auto builder2 = new MessageBuilder();
		auto root2 = builder2.getRoot!TestAllTypes();
		root2.setStructField(root.asReader());
		TestUtil.checkTestMessage(root2.getStructField());
	}
	
	{
		auto builder2 = new MessageBuilder();
		auto root2 = builder2.getRoot!TestAnyPointer();
		root2.getAnyPointerField().setAs!TestAllTypes(root.asReader());
		TestUtil.checkTestMessage(root2.getAnyPointerField.getAs!TestAllTypes());
	}
}

//SerializedSize
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!TestAnyPointer();
	root.getAnyPointerField().setAs!Text(Text.Reader("12345"));
	
	//One word for segment table, one for the root pointer,
	//one for the body of the TestAnyPointer struct,
	//and one for the body of the Text.
	assert(Serialize.computeSerializedSizeInWords(builder) == 4);
}

//Import
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!Foo();
	auto field = root.initImportedStruct();
	TestUtil.initTestMessage(field);
	TestUtil.checkTestMessage(field);
	TestUtil.checkTestMessage(field.asReader());
}

//GenericMap
unittest
{
	auto builder = new MessageBuilder();
	auto root = builder.initRoot!(GenericMap!(Text, TestAllTypes))();
	
	{
		auto entries = root.initEntries(3);
		
		auto entry0 = entries.get(0);
		entry0.setKey(Text.Reader("foo"));
		auto value0 = entry0.initValue();
		value0.setInt64Field(101);
		
		auto entry1 = entries.get(1);
		entry1.setKey(Text.Reader("bar"));
		auto value1 = entry1.initValue();
		value1.setInt64Field(202);
		
		auto entry2 = entries.get(2);
		entry2.setKey(Text.Reader("baz"));
		auto value2 = entry2.initValue();
		value2.setInt64Field(303);
	}
	
	{
		auto entries = root.asReader().getEntries();
		auto entry0 = entries.get(0);
		assert(entry0.getKey().toString() == "foo");
		assert(entry0.getValue().getInt64Field() == 101);
		
		auto entry1 = entries.get(1);
		assert(entry1.getKey().toString() == "bar");
		assert(entry1.getValue().getInt64Field() == 202);
		
		auto entry2 = entries.get(2);
		assert(entry2.getKey().toString() == "baz");
		assert(entry2.getValue().getInt64Field == 303);
	}
}
