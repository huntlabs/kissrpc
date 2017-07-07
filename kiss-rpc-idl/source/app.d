module app;

import IDL.idl_parse;
import std.stdio;

void main(string[] args)
{
	if(args.length < 3)
	{
		writefln("input parse idl path! or output file name");
	}else
	{
		writeln("conmand: " ~args);
	
		auto idl = new idl_parse;
		
		idl.setParseFile(args[1]);
		idl.setFileName(args[2]);

		if(args.length == 4)
		{
			idl.setOutputFile(args[3]);
		}

		idl.startParse();
	}
}