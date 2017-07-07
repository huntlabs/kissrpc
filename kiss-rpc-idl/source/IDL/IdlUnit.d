module IDL.IdlUnit;
import IDL.IdlParseStruct;

static IdlParseStruct[string] idlStructList;
static string[string] idlDlangVariable;

enum CODE_LANGUAGE{
	CL_DLANG,
	CL_CPP,
	CL_JAVA,
	CL_GOLANG
}
