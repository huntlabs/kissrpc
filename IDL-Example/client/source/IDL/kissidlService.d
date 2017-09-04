module kissrpc.IDL.kissidlService;


import kissrpc.IDL.kissidlInterface;
import kissrpc.IDL.kissidlMessage;

import kissrpc.RpcClient;
import kissrpc.Unit;


class RpcAddressBookService: RpcAddressBookInterface{

	this(RpcClient rpClient){
		RpcBindFunctionMap[712866408] = typeid(&RpcAddressBookService.getContactList).toString();
		super(rpClient);
	}

	Contacts getContactList(AccountName accountName, const RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS){

		Contacts ret = super.getContactListInterface(accountName, compressType, secondsTimeOut);
		return ret;
	}


	void getContactList(AccountName accountName, RpcgetContactListCallback rpcCallback, const RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS){

		super.getContactListInterface(accountName, rpcCallback, compressType, secondsTimeOut);
	}


}



