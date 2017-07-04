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
		
		idl.set_parse_file(args[1]);
		idl.set_file_name(args[2]);

		if(args.length == 4)
		{
			idl.set_output_file(args[3]);
		}

		idl.start_parse();
	}
}