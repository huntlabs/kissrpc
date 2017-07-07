module KissRpc.IDL.KissIdlService;


import KissRpc.IDL.KissIdlInterface;
import KissRpc.IDL.KissIdlMessage;

import KissRpc.RpcClient;

class RpcAddressBookService: RpcAddressBookInterface{

	this(RpcClient rpClient){
		super(rpClient);
	}

	contacts getContactList(string accountName){

		contacts ret = super.getContactListInterface(accountName);
		return ret;
	}


	void getContactList(string accountName, RpcgetContactListCallback rpcCallback){

		super.getContactListInterface(accountName, rpcCallback);
	}


}



