@0x9450b526a9ec41c6;

using Dlang = import"../../../../../../home/jasonsalex/桌面/capnproto-dlang-master/compiler/src/main/schema/capnp/dlang.capnp";


$Dlang.module("kiss-capnp-buf");

struct ArgsType{    
	
	type @0 :Type;	  	

	payload @1 :Text; 	

	enum Type{
		tVoid @0;
		tBool @1;
		tByte @2;
		tShort @3;
		tInt @4;
		tLong @5;
		tUbyte @6;
		tUshort @7;
		tUint @8;
		tUlong @9;
		tFloat @10;
		tDouble @11;
		tReal @12;
		tChar @13;
		tWchar @14;
		tDchar @15;
		tClass @16;
		tString @17;
		tArray @18;	
	}

}



struct Payload{
	callInterface @0 :Text;  	
	args @1 :List(ArgsType);  	
	statusString @2 :Text;			
}
