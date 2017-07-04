module IDL.idl_unit;
import IDL.idl_parse_struct;

static idl_parse_struct[string] idl_struct_list;
static string[string] idl_dlang_variable;

enum CODE_LANGUAGE{
	CL_DLANG,
	CL_CPP,
	CL_JAVA,
	CL_GOLANG
}
