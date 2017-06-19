module IDL.idl_base_interface;

import IDL.idl_unit;

interface idl_base_interface
{
	bool parse(string name, string struct_bodys);
	string get_name();
	string create_server_code_for_language(CODE_LANGUAGE language);
	string create_client_code_for_language(CODE_LANGUAGE language);

}

