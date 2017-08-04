module KissRpc.IDL.kissidlMessage;
import std.typetuple;


struct UserInfo{

	string name;
	int age;
	double widget;
}


struct Contacts{

	int number;
	UserInfo[] userInfoList;
}


struct AccountName{

	string name;
	int count;
}


