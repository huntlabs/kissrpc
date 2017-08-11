
# What is IDL?
    1. IDL is the kiss RPC interface code generation protocol, the preparation of IDL protocol, you can generate the corresponding server and client common RPC code call interface.
    2. Standardize the unity, interface unification, simple to use.


# IDL usage
    1. [idl file path]    [output file name]    [output file path，default current dir]  E."/root/home/kiss-rpc.idl"	kiss-rpc	"/root/home/rpc/"
    2. module name output, module path is ".": E."/root/home/kiss-rpc.idl"	module.test.kiss-rpc	 "/root/home/rpc/"	
    3. At the same time output client and server file code, only need to copy to the corresponding client and server directory.
    4. Message type names must be uppercase first, type members must be marked with serial numbers, otherwise they cannot be compiled 	
    5. The function parameter list can only be one, or else it cannot be compiled


IDL                 |           D lang
--------------------|---------------------
bool                |           bool
byte                |           byte
ubyte               |           ubyte
short               |           short
ushort		    |		ushort
int                 |           int
uint                |           uint
long                |	    	long    
ulong               |           ulong
float               |           float
double              |           double
char                |           char
string              |           string
[]                  |           DynamicArrayList
@message      	    |	    	struct

# IDL code usage
    1. IDL code usage, server-side as long as the server directory to fill the service file function interface code.

    2. The client only needs to call the function of the interface of the service file under the client directory.

# Kiss-rpc IDL writing examples
```
	//kiss rpc idl demo

	@message:UserInfo
	{
		string phone:3;
		string userName:1;
		int age:2;
		double wiget:4;
		
		string[] addressList:5;
	}

	@message:Contacts
	{
		int number:1;
		UserInfo[] userInfoList:2;		
	}

	@message:User
	{
		string name:1;
	}


	@service:AddressBook	//class interface
	{
		Contacts getContactList(User userName);
	}


```

# Client remote call(demo path:IDL-Example/client/source/app.d):


###### IDL generates both synchronous and asynchronous interfaces, and asynchronous interfaces are all parameter callbacks.

* import hander files

```
import KissRpc.IDL.kissidlService;
import KissRpc.IDL.kissidlMessage;
import KissRpc.Unit;
```


* Client synchronous invocation
```
			try{
				auto c = addressBookService.getContactList(name);
				foreach(v; c.userInfoList)
				{
					writefln("sync number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
					
				}

			}catch(Exception e)
			{
				writeln(e.msg);
			}

```
* Client asynchronous call

```
			try{

				addressBookService.getContactList(name, delegate(Contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("async number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
						}
					}
				);
			}catch(Exception e)
			{
				writeln(e.msg);
			}
```

###### Call in compression (support for dynamic compression and forced compression)

*  Bind socket mode compression

```
RpcClient.setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC); //The dynamic compression mode defaults to more than 200 bytes of compression

RpcClient.setSocketCompress(RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS); //forced compression method

```

* Single request compression, synchronous call, forced compression

```
			//use compress demo
			try{
				auto c = addressBookService.getContactList(name, RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS);

				foreach(v; c.userInfoList)
				{
					writefln("compress test: sync number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
				}
				
			}catch(Exception e)
			{
				writeln(e.msg);
			}
```

* Single request compression, asynchronous call, 100 bytes of dynamic compression, request timeout 30 seconds

```
			//use dynamic compress and set request timeout


			try{
				RPC_PACKAGE_COMPRESS_DYNAMIC_VALUE = 100; //reset compress dynamaic value 100 byte, default:200 byte

				addressBookService.getContactList(name, delegate(Contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("dynamic compress test: sync number:%s, name:%s, phone:%s, age:%s", c.number, v.name, v.widget, v.age);
						}

					}, RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC, 30
				);

			}catch(Exception e)
			{
				writeln(e.msg);
			}

```


# Server service file code rpc_address_book_service(file path:IDL-Example/server/source/IDL/kissidlInterface.d):

######  The server interface can handle asynchronous events.

*  RpcAddressBookService.getContactList

```
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
```


