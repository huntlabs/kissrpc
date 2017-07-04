module IDL.idl_base_interface;

import IDL.idl_unit;
import IDL.idl_parse_struct;

interface idl_base_interface
{
	bool parse(string name, string struct_bodys);
	string get_name();
	string create_server_code_for_interface(CODE_LANGUAGE language);
	string create_server_code_for_service(CODE_LANGUAGE language);

	string create_client_code_for_service(CODE_LANGUAGE language);
	string create_client_code_for_interface(CODE_LANGUAGE language);
}

