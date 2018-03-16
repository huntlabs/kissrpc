


import std.stdio;
import std.getopt;
import std.file;

import Parse;
import CreateFile;
import Constant;

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
	if (exists(generateDir))
		rmdirRecurse(generateDir);
	mkdirRecurse(generateDir);
	
	auto parser = new Parse();
	if (parser.doParse(idlFile, generateDir) == false) {
		rmdirRecurse(generateDir);
	}

	auto creater = new CreateFile(parser.getServices(), parser.getMessages(), parser.getModule(), generateDir);
	creater.createFlatbufferFile();
	creater.createClassFile();
	creater.createClientStub();

}
