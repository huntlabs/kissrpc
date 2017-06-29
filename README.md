# kiss-rpc:
* features: analog stack call mode, support for multiple value returns, multi-layer type structure nested, multi-layer array embedded, support IDL protocol writing. The call is simple and secure, and the server uses multi-threaded asynchronous mode to mine server performance. Client supports multi-threaded synchronization and asynchronous mode, timeout mechanism, Linux support epoll network model, analog grpc, thrift, Dubbo, several times faster or even dozens of times.
* environment: Linux, UNIX, windows, macOS
* transport protocol: capnproto
* development language: dlang
* compiler: DMD
* github:https://github.com/huntlabs/kiss-rpc
* developer notes: [Development Notes] (http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ3xapdS0TaQCk2ieqTL2UN24T)
* 简书介绍:http://www.jianshu.com/p/68d5bed1887b

# IDL introduction and instructions for use:
* IDL protocol preparation and use of instructions: [IDL protocol detailed description] (http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ02PboQ0P_kXV2XlO0z3W9I69)


#### Setup:
1. install capnproto (https://capnproto.org/install.html)

2. dmd Compiler

#### Example:
1. Asynchronous test:

	single connection: "example/app-async-single.d"

	mutil connection: "example/app-async-mutil.d"

2. Synchronous test:
	
	single connection: "example/app-sync-block-single.d"
	
	mutil connection: "example/app-sync-block-mutil.d"
<<<<<<< HEAD

#### IDL Example

1. client test: "IDL-Example/client/app.d"

2. server test: "IDL-Example/server/app.d"

3. idl protocol: "IDL-Example/kiss-idl"
=======

#### IDL Example

1. client test: "IDL-Example/client/app.d"

2. server test: "IDL-Example/server/app.d"

3. idl protocol: "IDL-Example/kiss-idl"

>>>>>>> ee9d48f4e41752a53c54bc682e98e373810f5a82

# 什么是IDL
            IDL是kiss-rpc接口代码生成协议，通过定义IDL，可以生成对应的服务端和客户端通用的RPC代码调用接口，不必手写生成相应的代码接口，规范统一化，接口统一化，使用简单。 下面就是IDL协议编写示例，以及生成的对应RPC代码接口源码示例。 如果你想要手动编写RPC代码接口的话，也是可以的，但我们不建议你那么做。

# IDL使用方式，
    [idl文件路径]    [输出名字]    [输出路径，默认为当前目录]
    同时输出client和server文件代码，只需要拷贝到对应的客户端和服务端目录就行了。

# 代码编写方式
    * 服务端只要填充service文件的接口代码就行了；
    * 客户端只需要调用server接口的文件就行了。

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
		sync: contacts sync_get_contact_list(string account_name);	//同步
		async: string async_get_contact_list(string account_name);	//异步
	}

```

# 客户端远程调用
* import files
```
    import KissRpc.IDL.kiss_idl_service;
    import KissRpc.IDL.kiss_idl_message;  
```


* client sync call rpc_address_book_service.sync_get_contact_list for server function
```
            auto contact = address_book_service.sync_get_contact_list("jasonalex");

            foreach(v; contact.user_info_list)
            {
                writefln("number:%s, name:%s, phone:%s, address list:%s", contact.number, v.user_name, v.phone, v.address_list);
            }  
```
* client async call rpc_address_book_service.async_get_contact_list for server fucntion

```
            address_book_service.async_get_contact_list("jasonsalex", delegate(contacts c){
                
                    foreach(v; contact.user_info_list)
                    {
                        writefln("async number:%s, name:%s, phone:%s, address list:%s", contact.number, v.user_name, v.phone, v.address_list);
                    }

                }
            );  
```

# 服务端service文件代码 rpc_address_book_servicec class:

* rpc_address_book_service.sync_get_contact_list

```
    contacts sync_get_contact_list(string account_name){

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

* rpc_address_book_service.async_get_contact_list
```
    contacts async_get_contact_list(string account_name){

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




<<<<<<< HEAD












=======
>>>>>>> ee9d48f4e41752a53c54bc682e98e373810f5a82
