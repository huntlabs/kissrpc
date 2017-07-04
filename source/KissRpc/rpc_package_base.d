module KissRpc.rpc_package_base;

import KissRpc.rpc_request;
import KissRpc.rpc_response;

interface rpc_package_base{
	rpc_request get_request_data();
	rpc_response get_response_data();

	ubyte[] to_binary_stream();
}
