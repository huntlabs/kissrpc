module KissRpc.IDL.kiss_idl_message;
import std.typetuple;


struct user_info{

	string[] address_list;
	double wiget;
	string phone;
	int age;
	string user_name;

	TypeTuple!(string[], double, string, int, string, ) member_list;

	void create_type_tulple(){

		member_list[0] = address_list;
		member_list[1] = wiget;
		member_list[2] = phone;
		member_list[3] = age;
		member_list[4] = user_name;
	}

	void restore_type_tunlp(){

		address_list = member_list[0];
		wiget = member_list[1];
		phone = member_list[2];
		age = member_list[3];
		user_name = member_list[4];
	}

}


struct contacts{

	user_info[] user_info_list;
	int number;

	TypeTuple!(user_info[], int, ) member_list;

	void create_type_tulple(){

		member_list[0] = user_info_list;
		member_list[1] = number;
	}

	void restore_type_tunlp(){

		user_info_list = member_list[0];
		number = member_list[1];
	}

}


