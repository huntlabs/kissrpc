module IDL.IdlUnit;

import std.uni;
import std.algorithm.iteration;
import std.array;
import std.conv;

import IDL.IdlParseStruct;

static IdlParseStruct[string] idlStructList;
static string[string] idlDlangVariable;

enum CODE_LANGUAGE{
	CL_DLANG,
	CL_CPP,
	CL_JAVA,
	CL_GOLANG
}

string stringToUpper(string s, const ulong pos)
{
	return  s.replaceFirst(to!string(s[pos]), to!string(toUpper(s[pos])));
}

string stringToLower(string s, const ulong pos)
{
	return  s.replaceFirst(to!string(s[pos]), to!string(toLower(s[pos])));
}