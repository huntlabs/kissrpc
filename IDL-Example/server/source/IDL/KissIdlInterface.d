module KissRpc.IDL.KissIdlInterface;

import KissRpc.IDL.KissIdlMessage;
import KissRpc.IDL.KissIdlService;

import KissRpc.RpcServer;
import KissRpc.RpcServerImpl;
import KissRpc.RpcResponse;
import KissRpc.RpcRequest;
abstract class RpcAddressBookInterface{ 

	this(RpcServer rpServer){ 
		rpImpl = new RpcServerImpl!(RpcAddressBookService)(rpServer); 
		rpImpl.bindRequestCallback("getContactList", &this.getContactListInterface); 

	}

	void getContactListInterface(RpcRequest req){

		auto resp = new RpcResponse(req);

		string accountName;


		req.pop(accountName);

		contacts ret_contacts;

		ret_contacts = (cast(RpcAddressBookService)this).getContactList(accountName);

		resp.push(ret_contacts);

		rpImpl.response(resp);
	}



	RpcServerImpl!(RpcAddressBookService) rpImpl;
}


