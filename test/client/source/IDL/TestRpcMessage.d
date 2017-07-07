module KissRpc.IDL.TestRpcMessage;
import std.typetuple;


struct UserInfo{

	int i;
	string name;

	TypeTuple!(int, string, ) memberList;

	void createTypeTulple(){

		memberList[0] = i;
		memberList[1] = name;
	}

	void restoreTypeTunlp(){

		i = memberList[0];
		name = memberList[1];
	}

}


