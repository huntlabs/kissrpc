# kiss-rpc:
* features: analog stack call mode, support for multiple value returns, multi-layer type structure nested, multi-layer array embedded, support IDL protocol writing. The call is simple and secure, and the server uses multi-threaded asynchronous mode to mine server performance. Client supports multi-threaded synchronization and asynchronous mode, timeout mechanism, Linux support epoll network model, analog grpc, thrift, Dubbo, several times faster or even dozens of times.

* environment: Linux, UNIX, windows, macOS
* transport protocol: capnproto
* development language: dlang
* compiler: dub
* github:https://github.com/huntlabs/kiss-rpc
* developer notes: [Development Notes] (http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ3xapdS0TaQCk2ieqTL2UN24T)
* 简书介绍:http://www.jianshu.com/p/68d5bed1887b

# IDL introduction and instructions for use:
* IDL protocol preparation and use of instructions: [IDL protocol detailed description] (http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ02PboQ0P_kXV2XlO0z3W9I69)


#### Setup:

1. install capnproto (https://capnproto.org/install.html)

2. dub Compiler

#### Example:

1. Asynchronous test:

	single connection: "example/app-async-single.d"

	mutil connection: "example/app-async-mutil.d"

2. Synchronous test:
	
	single connection: "example/app-sync-block-single.d"
	
	mutil connection: "example/app-sync-block-mutil.d"


#### IDL Example

1. client test: "IDL-Example/client/"

2. server test: "IDL-Example/server/"

3. idl protocol: "IDL-Example/kiss-idl"


#### Performance test code
1. 50W QPS synchronous testing takes time: 15 seconds, average 3.3w QPS per second

2. 50W QPS asynchronous testing takes 9 seconds, with an average of 5.5W QPS per second

3. 1000 concurrent, 100wQPS asynchronous testing takes time: 25 seconds, average QPS:4W per second

* server test code:"test/server"

* client test code: "test/client"

![](http://e222f542.wiz03.com/share/resources/e1299376-372b-4994-9239-adefb8c42137/index_files/69039892.png)
![](http://e222f542.wiz03.com/share/resources/e1299376-372b-4994-9239-adefb8c42137/index_files/59007921.png)

# What is IDL?
    1. IDL is the kiss RPC interface code generation protocol, the preparation of IDL protocol, you can generate the corresponding server and client common RPC code call interface.

    2. Standardize the unity, interface unification, simple to use.


# IDL usage
    1. [idl file path]    [output file name]    [output file path，default current dir]  E."/root/home/kiss-rpc.idl"	kiss-rpc	"/root/home/rpc/"

    2. At the same time output client and server file code, only need to copy to the corresponding client and server directory.


# IDL Supported type

IDL                 |            D lang
----------------|----------------
bool                |            bool
byte                |            byte
ubyte              |            ubyte
short               |            short
int                   |            int
uint                 |            uint
long                |	    long    
ulong              |            ulong
float                |            float
double            |            double
char                |            char
wchar             |	   wchar
string              |            string
@message      |	    struct



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

	@message:contacts
	{
		int number:1;
		UserInfo[] userInfoList:2;		
	}


	@service:AddressBook	//class interface
	{
		contacts getContactList(string accountName);
	}


```

# Client remote call


###### IDL generates both synchronous and asynchronous interfaces, and asynchronous interfaces are all parameter callbacks.

* import hander files

```
import KissRpc.IDL.KissIdlService;
import KissRpc.IDL.KissIdlMessage;
```


* Client synchronous invocation
```
			try{

				auto c = addressBookService.getContactList("jasonalex");
				foreach(v; c.userInfoList)
				{
					writefln("sync number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
					
				}

			}catch(Exception e)
			{
				writeln(e.msg);
			}

```
* Client asynchronous call

```
 			try{

				addressBookService.getContactList("jasonsalex", delegate(contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("async number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
						}
					}
					);
			}catch(Exception e)
			{
				writeln(e.msg);
			}
```

# Server service file code rpc_address_book_service:

######  The server interface can handle asynchronous events.

*  RpcAddressBookService.getContactList

```
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
```


