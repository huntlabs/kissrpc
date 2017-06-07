Ultra high performance RPC for D dlang

Kiss-rpc Features: 
		analog stack call mode, the server uses multi-threaded asynchronous mode, mining server performance. Client supports multi-threaded synchronization and asynchronous mode, timeout mechanism, simple and safe call, Linux support epoll network model, analog grpc, thrift, Dubbo, several times faster or even dozens of times.
		
		
Environment: linux, unix, windows, macOS

Kiss-rpc introduction and testing: http://www.jianshu.com/p/a53f886f4e98


1.install capnproto (https://capnproto.org/install.html)

2.dmd Compiler

3.Asynchronous test:

	single connection: "kiss-rpc/example/app-async-single.d"

	mutil connection: "kiss-rpc/example/app-async-mutil.d"

4.Synchronous test:
	
	single connection: "kiss-rpc/example/app-sync-block-single.d"
	
	mutil connection: "kiss-rpc/example/app-sync-block-mutil.d"
	
