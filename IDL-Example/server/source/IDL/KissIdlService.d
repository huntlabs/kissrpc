module KissRpc.IDL.KissIdlService;

import KissRpc.IDL.KissIdlInterface;
import KissRpc.IDL.KissIdlMessage;

import KissRpc.RpcServer;

import std.conv;

class RpcAddressBookService: RpcAddressBookInterface{

	this(RpcServer rpServer){
		super(rpServer);
	}
	void test()
	{
	}
	contacts getContactList(string accountName){
		
		contacts contactsRet;
		
		contactsRet.number = 100;
		contactsRet.userInfoList = new UserInfo[10];
		
		
		foreach(i,ref v; contactsRet.userInfoList)
		{
			v.phone ~= "135167321"~to!string(i);
			v.age = cast(int)i;
			v.userName = accountName~to!string(i);
			v.addressList = new string[2];
			v.addressList[0] =  accountName ~ "address1 :" ~ to!string(i);
			v.addressList[1] =  accountName ~ "address2 :" ~ to!string(i);
			
		}


		return contactsRet;
	}


}



