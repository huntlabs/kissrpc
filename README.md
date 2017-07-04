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

* server test code:"test/server"

* client test code: "test/client"

![](http://e222f542.wiz03.com/share/resources/e1299376-372b-4994-9239-adefb8c42137/index_files/69039892.png)

# 什么是IDL
    1. IDL是kiss rpc接口代码生成协议, 编写IDL协议, 可以生成对应的服务端和客户端通用的RPC代码调用接口.
    2. 规范统一化, 接口统一化, 使用简单.

# IDL使用方式
    1. [idl文件路径]    [输出名字]    [输出路径，默认为当前目录].
    2. 同时输出client和server文件代码，只需要拷贝到对应的客户端和服务端目录就行了.

# IDL代码使用方式
    1. 服务端只要填充server目录下service文件的函数接口代码.
    2. 客户端只需要调用client目录下service文件的接口的函数.

# kiss-rpc IDL 编写示例
```
	//kiss rpc idl demo

	@message:user_info
	{
		string phone:3;
		string user_name:1;
		int age:2;
		double wiget:4;
		
		string[] address_list:5;
	}

	@message:contacts
	{
		int number:1;
		user_info[] user_info_list:2;		
	}


	@service:address_book	//接口类
	{
		contacts get_contact_list(string account_name);
	}


```

# 客户端远程调用

###### IDL会同时生成同步接口和异步接口，异步接口都为参数回调的方式。

* 倒入头文件
```
    import KissRpc.IDL.kiss_idl_service;
    import KissRpc.IDL.kiss_idl_message;  
```


* 客户端同步调用
```
    auto contact = address_book_service.get_contact_list("jasonalex");
    
    foreach(v; contact.user_info_list)
    {
        writefln("number:%s, name:%s, phone:%s, address list:%s", contact.number, v.user_name, v.phone, v.address_list);
    }
```
* 客户端异步调用

```
    address_book_service.get_contact_list("jasonsalex", delegate(contacts c){
            foreach(v; c.user_info_list)
            {
                writefln("async number:%s, name:%s, phone:%s, address list:%s", contact.number, v.user_name, v.phone, v.address_list);
             }
        });  
```

# 服务端service文件代码 rpc_address_book_service:
###### 服务端接口都会异步事件处理。

* rpc_address_book_service.sync_get_contact_list

```
    contacts get_contact_list(string account_name){

        contacts contacts_ret;

        import std.conv;
        import std.stdio;

        contacts_ret.number = 100;
        contacts_ret.user_info_list = new user_info[10];


        foreach(i,ref v; contacts_ret.user_info_list)
        {
            v.phone ~= "135167321"~to!string(i);
            v.age = cast(int)i;
            v.user_name = account_name~to!string(i);
            v.address_list = new string[2];
            v.address_list[0] =  account_name ~ "address1 :" ~ to!string(i);
            v.address_list[1] =  account_name ~ "address2 :" ~ to!string(i);

        }

        return contacts_ret;
    }  
```


