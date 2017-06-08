# Ultra high performance RPC for D dlang

###### Kiss-rpc Features: Analog stack call, support multi valued return, simple and safe call, the server adopts multi-threaded asynchronous mode, mining server performance. Client supports multi-threaded synchronization and asynchronous mode, timeout mechanism, Linux support epoll network model, analog grpc, thrift, Dubbo, several times faster or even dozens of times
		
		
 #### Environment: linux, unix, windows, macOS

 #### Kiss-rpc introduction and testing: http://www.jianshu.com/p/68d5bed1887b

 #### Developer notes:[kiss-rpc developer note](http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ3xapdS0TaQCk2ieqTL2UN24T)


#### Setup:
1. install capnproto (https://capnproto.org/install.html)

2. dmd Compiler

#### Example:
1. Asynchronous test:

	single connection: "kiss-rpc/example/app-async-single.d"

	mutil connection: "kiss-rpc/example/app-async-mutil.d"

2. Synchronous test:
	
	single connection: "kiss-rpc/example/app-sync-block-single.d"
	
	mutil connection: "kiss-rpc/example/app-sync-block-mutil.d"
	
