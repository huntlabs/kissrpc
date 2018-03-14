


import std.stdio;
import std.getopt;
import std.file;

import Parse;

void main(string[] args)
{
	string idlFile = "./test.idl";
	string outPath = "./";
	auto oprions = getopt(args,"file|f","idle file fullpath", &idlFile,"path|p","output path", &outPath);
	if (oprions.helpWanted){
		defaultGetoptPrinter("example : ./kiss-rpc-idl -f ./test.idl -p ./", oprions.options);
		return ;
	}
	if (!exists(idlFile)) {
		writeln(idlFile ~ " not exsit!");
		return;
	}
	string generateDir = outPath~"rpcgenerate";
	mkdirRecurse(generateDir);
	
	auto parser = new Parse();
	if (parser.doParse(idlFile, generateDir) == false) {
		rmdirRecurse(generateDir);
	}
}
