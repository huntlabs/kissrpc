module KissRpc.IDL.KissIdlService;


import KissRpc.IDL.KissIdlInterface;
import KissRpc.IDL.KissIdlMessage;

import KissRpc.RpcClient;
import KissRpc.Unit;

class RpcAddressBookService: RpcAddressBookInterface{

	this(RpcClient rpClient){
		super(rpClient);
	}

	contacts getContactList(string accountName, const RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS){

		contacts ret = super.getContactListInterface(accountName, compressType, secondsTimeOut);
		return ret;
	}


	void getContactList(string accountName, RpcgetContactListCallback rpcCallback, const RPC_PACKAGE_COMPRESS_TYPE compressType = RPC_PACKAGE_COMPRESS_TYPE.RPCT_NO, const int secondsTimeOut = RPC_REQUEST_TIMEOUT_SECONDS){

		super.getContactListInterface(accountName, rpcCallback, compressType, secondsTimeOut);
	}


}



