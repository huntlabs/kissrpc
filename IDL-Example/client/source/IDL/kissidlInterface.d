module KissRpc.IDL.kissidlInterface;

import KissRpc.IDL.kissidlMessage;
import KissRpc.IDL.kissidlService;

import KissRpc.RpcRequest;
import KissRpc.RpcClientImpl;
import KissRpc.RpcClient;
import KissRpc.RpcResponse;
import KissRpc.Unit;
import flatbuffers;
import KissRpc.IDL.flatbuffer.kissidl;

abstract class RpcAddressBookInterface{ 

	this(RpcClient rpClient){ 
		rpImpl = new RpcClientImpl!(RpcAddressBookService)(rpClient); 
	}

	Contacts getContactListInterface(const AccountName accountName, const RPC_PACKAGE_COMPRESS_TYPE compressType, const int secondsTimeOut, const size_t funcId = 712866408){

		auto builder = new FlatBufferBuilder(512);

		//input flatbuffer code for AccountNameFB class




				auto accountNamePos = AccountNameFB.createAccountNameFB(builder, builder.createString(accountName.name), accountName.count, );


		builder.finish(accountNamePos);

		auto req = new RpcRequest(compressType, secondsTimeOut);

		req.push(builder.sizedByteArray);

		RpcResponse resp = rpImpl.syncCall(req, RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, funcId);

		if(resp.getStatus == RESPONSE_STATUS.RS_OK){

			ubyte[] flatBufBytes;
			resp.pop(flatBufBytes);

			auto ret_ContactsFB = ContactsFB.getRootAsContactsFB(new ByteBuffer(flatBufBytes));
			Contacts ret_Contacts;

			//input flatbuffer code for ContactsFB class




				ret_Contacts.number = ret_ContactsFB.number;
		foreach(userInfoList; ret_ContactsFB.userInfoList){

			UserInfo userInfoTmp;
			userInfoTmp.name = userInfoList.name;
			userInfoTmp.age = userInfoList.age;
			userInfoTmp.widget = userInfoList.widget;
			ret_Contacts.userInfoList ~= userInfoTmp;
		}



			return ret_Contacts;
		}else{
			throw new Exception("rpc sync call error, function:" ~ RpcBindFunctionMap[funcId]);
		}
	}


	alias RpcgetContactListCallback = void delegate(Contacts);

	void getContactListInterface(const AccountName accountName, RpcgetContactListCallback rpcCallback, const RPC_PACKAGE_COMPRESS_TYPE compressType, const int secondsTimeOut, const size_t funcId = 712866408){

		auto builder = new FlatBufferBuilder(512);
		//input flatbuffer code for AccountNameFB class




				auto accountNamePos = AccountNameFB.createAccountNameFB(builder, builder.createString(accountName.name), accountName.count, );


		builder.finish(accountNamePos);
		auto req = new RpcRequest(compressType, secondsTimeOut);

		req.push(builder.sizedByteArray);

		rpImpl.asyncCall(req, delegate(RpcResponse resp){

			if(resp.getStatus == RESPONSE_STATUS.RS_OK){

				ubyte[] flatBufBytes;
				Contacts ret_Contacts;

				resp.pop(flatBufBytes);

				auto ret_ContactsFB = ContactsFB.getRootAsContactsFB(new ByteBuffer(flatBufBytes));
				//input flatbuffer code for ContactsFB class




				ret_Contacts.number = ret_ContactsFB.number;
		foreach(userInfoList; ret_ContactsFB.userInfoList){

			UserInfo userInfoTmp;
			userInfoTmp.name = userInfoList.name;
			userInfoTmp.age = userInfoList.age;
			userInfoTmp.widget = userInfoList.widget;
			ret_Contacts.userInfoList ~= userInfoTmp;
		}



				rpcCallback(ret_Contacts);
			}else{
				throw new Exception("rpc sync call error, function:" ~ RpcBindFunctionMap[funcId]);
			}}, RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, funcId);
	}


	RpcClientImpl!(RpcAddressBookService) rpImpl;
}


