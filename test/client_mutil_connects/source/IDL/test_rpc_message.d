module KissRpc.IDL.test_rpc_message;
import std.typetuple;


struct user_info{

	int i;
	string name;

	TypeTuple!(int, string, ) member_list;

	void create_type_tulple(){

		member_list[0] = i;
		member_list[1] = name;
	}

	void restore_type_tunlp(){

		i = member_list[0];
		name = member_list[1];
	}

}


