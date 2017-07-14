# kiss-rpc features:
1. Lightweight and easy to use. There are two ways to support IDL and manually write protocols. Analog function call, more in line with the RPC remote call logic, simple, transparent.

2. Easy to change, easy to use, existing code can be used directly

3. Data formats support backward compatibility

4. Support multi valued return feature, support timeout mechanism, analog grpc, thrift, Dubbo fast several times or even dozens of times.

5. Support snappy compression algorithm, compression speed, superior performance.

6. Support pipeline data compression, dynamic data compression, request data compression, flexible use of a wide range of scenarios.


###### 开发环境

* environment: Linux, UNIX, windows, macOS
* transport protocol: capnproto(Install dependency Libraries:https://github.com/capnproto/capnproto)
* Compression protocol: snappy(Install dependency Libraries:https://github.com/google/snappy)
* development language: dlang
* compiler: dub
* github:https://github.com/huntlabs/kiss-rpc
* developer notes: [Development Notes] (http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ3xapdS0TaQCk2ieqTL2UN24T)
* 简书介绍:http://www.jianshu.com/p/68d5bed1887b

# IDL introduction and instructions for use:
* IDL protocol preparation and use of instructions: [IDL protocol detailed description] (http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ02PboQ0P_kXV2XlO0z3W9I69)


#### Setup:

1. install capnproto (https://capnproto.org/install.html)
2. install google snappy
3. dub Compiler

#### About the compression mode used by kiss-rpc

* data compression: using Google snappy compression technology to support forced compression and dynamic compression, flexible compression methods can be applied to a variety of scenarios.

* dynamic compression technique: when data packets larger than 200 bytes or set the threshold, compressed packet, otherwise not compressed packets, use and help to improve the performance of space, response will be based on whether the request needs dynamic data compression.

* single request compression: compression of a single request request, and response compression based on the way data packets are pressed.


* pipeline compression: packet compression can be performed on the specified pipeline.


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

# Client remote call(demo path:IDL-Example/client/source/app.d):


###### IDL generates both synchronous and asynchronous interfaces, and asynchronous interfaces are all parameter callbacks.

* import hander files

```
import KissRpc.IDL.KissIdlService;
import KissRpc.IDL.KissIdlMessage;
import KissRpc.Unit;
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
				writeln("-------------------------user request compress---------------------------------------------");
				auto c = addressBookService.getContactList("jasonalex", RPC_PACKAGE_COMPRESS_TYPE.RPCT_COMPRESS);
				foreach(v; c.userInfoList)
				{
					writefln("compress test: sync number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
					
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

				addressBookService.getContactList("jasonsalex", delegate(contacts c){
						
						foreach(v; c.userInfoList)
						{
							writefln("dynamic compress test: async number:%s, name:%s, phone:%s, address list:%s", c.number, v.userName, v.phone, v.addressList);
						}
					}, RPC_PACKAGE_COMPRESS_TYPE.RPCT_DYNAMIC, 30
					);
			}catch(Exception e)
			{
				writeln(e.msg);
			}

```


# Server service file code rpc_address_book_service(file path:IDL-Example/server/source/app.d):

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


