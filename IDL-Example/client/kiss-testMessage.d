module KissRpc.IDL.kiss-testMessage;
import std.typetuple;


struct UserInfo{

	string[] addressList;
	double wiget;
	string phone;
	int age;
	string userName;

	TypeTuple!(string[], double, string, int, string, ) memberList;

	void createTypeTulple(){

		memberList[0] = addressList;
		memberList[1] = wiget;
		memberList[2] = phone;
		memberList[3] = age;
		memberList[4] = userName;
	}

	void restoreTypeTunlp(){

		addressList = memberList[0];
		wiget = memberList[1];
		phone = memberList[2];
		age = memberList[3];
		userName = memberList[4];
	}

}


struct contacts{

	UserInfo[] userInfoList;
	int number;

	TypeTuple!(UserInfo[], int, ) memberList;

	void createTypeTulple(){

		memberList[0] = userInfoList;
		memberList[1] = number;
	}

	void restoreTypeTunlp(){

		userInfoList = memberList[0];
		number = memberList[1];
	}

}


