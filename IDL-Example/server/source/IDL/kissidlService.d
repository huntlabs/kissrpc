module kissrpc.IDL.kissidlService;

import kissrpc.IDL.kissidlInterface;
import kissrpc.IDL.kissidlMessage;

import kissrpc.RpcServer;
import kissrpc.Unit;
import std.conv;

class RpcAddressBookService: RpcAddressBookInterface{

	this(RpcServer rpServer){
		RpcBindFunctionMap[712866408] = typeid(&RpcAddressBookService.getContactList).toString();
		super(rpServer);
	}

	Contacts getContactList(AccountName accountName){

		Contacts contactsRet;
		//input service code for Contacts class
		contactsRet.number = accountName.count;

		for(int i = 0; i < 10; i++)
		{
			UserInfo userInfo;
			userInfo.age = 18+i;
			userInfo.name = accountName.name ~ to!string(i);
			userInfo.widget = 120+i;
			contactsRet.userInfoList ~= userInfo;
		}

		return contactsRet;
	}



}



