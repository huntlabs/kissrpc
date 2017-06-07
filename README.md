Ultra high performance RPC for D dlang

Kiss-rpc Features: 
		analog stack call mode, the server uses multi-threaded asynchronous mode, mining server performance. Client supports multi-threaded synchronization and asynchronous mode, timeout mechanism, simple and safe call, Linux support epoll network model, analog grpc, thrift, Dubbo, several times faster or even dozens of times.
		
		
Environment: linux, unix, windows, macOS

Kiss-rpc introduction and testing: http://www.jianshu.com/p/68d5bed1887b
Developer notes: http://e222f542.wiz03.com/share/s/3y8Ll23R1kuW2E2Bv211ZNaJ0CD40M16VAzs2tpsxy2bq6Ha


1.install capnproto (https://capnproto.org/install.html)

2.dmd Compiler

3.Asynchronous test:

	single connection: "kiss-rpc/example/app-async-single.d"

	mutil connection: "kiss-rpc/example/app-async-mutil.d"

4.Synchronous test:
	
	single connection: "kiss-rpc/example/app-sync-block-single.d"
	
	mutil connection: "kiss-rpc/example/app-sync-block-mutil.d"
	
