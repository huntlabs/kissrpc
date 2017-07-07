module KissRpc.IDL.KissIdlInterface;

import KissRpc.IDL.KissIdlMessage;
import KissRpc.IDL.KissIdlService;

import KissRpc.RpcRequest;
import KissRpc.RpcClientImpl;
import KissRpc.RpcClient;
import KissRpc.RpcResponse;

abstract class RpcAddressBookInterface{ 

	this(RpcClient rpClient){ 
		rpImpl = new RpcClientImpl!(RpcAddressBookService)(rpClient); 
	}

	contacts getContactListInterface(string accountName, string bindFunc = __FUNCTION__){

		auto req = new RpcRequest;

		req.push(accountName);

		RpcResponse resp = rpImpl.syncCall(req, bindFunc);

		if(resp.getStatus == RESPONSE_STATUS.RS_OK){
			contacts ret_contacts;

			resp.pop(ret_contacts);

			return ret_contacts;
		}else{
			throw new Exception("rpc sync call error, function:" ~ bindFunc);
		}
	}


	alias RpcgetContactListCallback = void delegate(contacts);

	void getContactListInterface(string accountName, RpcgetContactListCallback rpcCallback, string bindFunc = __FUNCTION__){

		auto req = new RpcRequest;

		req.push(accountName);

		rpImpl.asyncCall(req, delegate(RpcResponse resp){

			if(resp.getStatus == RESPONSE_STATUS.RS_OK){

				contacts ret_contacts;

				resp.pop(ret_contacts);

				rpcCallback(ret_contacts);
			}else{
				throw new Exception("rpc sync call error, function:" ~ bindFunc);
			}}, bindFunc);
	}


	RpcClientImpl!(RpcAddressBookService) rpImpl;
}


