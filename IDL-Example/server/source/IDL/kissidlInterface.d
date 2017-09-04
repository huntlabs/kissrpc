module kissrpc.IDL.kissidlInterface;

import kissrpc.IDL.kissidlMessage;
import kissrpc.IDL.kissidlService;

import kissrpc.RpcServer;
import kissrpc.RpcServerImpl;
import kissrpc.RpcResponse;
import kissrpc.RpcRequest;
import flatbuffers;
import kissrpc.IDL.flatbuffer.kissidl;

abstract class RpcAddressBookInterface{ 

	this(RpcServer rpServer){ 
		rpImpl = new RpcServerImpl!(RpcAddressBookService)(rpServer); 
		rpImpl.bindRequestCallback(712866408, &this.getContactListInterface); 

	}

	void getContactListInterface(RpcRequest req){

		ubyte[] flatBufBytes;

		auto resp = new RpcResponse(req);
		req.pop(flatBufBytes);

		auto accountNameFB = AccountNameFB.getRootAsAccountNameFB(new ByteBuffer(flatBufBytes));
		AccountName accountName;

		//input flatbuffer code for AccountNameFB class



				accountName.name = accountNameFB.name;
		accountName.count = accountNameFB.count;


		auto ret_Contacts = (cast(RpcAddressBookService)this).getContactList(accountName);

		auto builder = new FlatBufferBuilder(512);
		//input flatbuffer code for ContactsFB class

		uint[] userInfoListPosArray;
		foreach(userInfoList; ret_Contacts.userInfoList){

				auto userInfoListPos = UserInfoFB.createUserInfoFB(builder, builder.createString(userInfoList.name), userInfoList.age, userInfoList.widget, );
			userInfoListPosArray ~= userInfoListPos;
		}

		auto ret_ContactsPos = ContactsFB.createContactsFB(builder, ret_Contacts.number, ContactsFB.createUserInfoListVector(builder, userInfoListPosArray), );


		builder.finish(ret_ContactsPos);

		resp.push(builder.sizedByteArray);

		rpImpl.response(resp);
	}



	RpcServerImpl!(RpcAddressBookService) rpImpl;
}


