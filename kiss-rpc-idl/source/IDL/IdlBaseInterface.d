module IDL.IdlBaseInterface;

import IDL.IdlUnit;
import IDL.IdlParseStruct;

interface IdlBaseInterface
{
	bool parse(string name, string structBodys);
	string getName();
	string createServerCodeForInterface(CODE_LANGUAGE language);
	string createServerCodeForService(CODE_LANGUAGE language);

	string createClientCodeForService(CODE_LANGUAGE language);
	string createClientCodeForInterface(CODE_LANGUAGE language);
}

