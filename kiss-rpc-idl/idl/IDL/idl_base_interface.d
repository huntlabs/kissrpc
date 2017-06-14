module IDL.idl_base_interface;

interface idl_base_interface
{
	bool parse(string name, string struct_bodys);
	string get_name();
	string create_server_code();
}

