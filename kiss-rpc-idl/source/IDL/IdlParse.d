module IDL.idl_parse;

import std.array;
import std.range.primitives : popFrontN;
import std.array : appender;
import std.regex;
import std.stdio;
import std.conv;
import std.file;
import std.format;
import std.process;

import IDL.IdlSymbol;
import IDL.IdlParseStruct;
import IDL.IdlParseInterface;
import IDL.IdlBaseInterface;
import IDL.IdlFlatbufferCreateCode;
import IDL.IdlUnit;

import core.thread;

class idl_parse
{
	this()
	{
		//idlDlangVariable["void"] = "void";
		idlDlangVariable["bool"] = "bool";
		idlDlangVariable["byte"] = "byte";
		idlDlangVariable["ubyte"] = "ubyte";
		idlDlangVariable["short"] = "short";
		idlDlangVariable["ushort"] = "ushort";
		idlDlangVariable["int"] = "int";
		idlDlangVariable["uint"] = "uint";
		idlDlangVariable["long"] = "long";
		idlDlangVariable["ulong"] = "ulong";
		idlDlangVariable["float"] = "float";
		idlDlangVariable["double"] = "double";
		idlDlangVariable["char"] = "char";
		idlDlangVariable["string"] = "string";
	}

	void setParseFile(string path)
	{
		inFilePath = path;
	}

	void setOutputFile(string path)
	{
		outFilePath = path;
	}

	void setFileName(string name)
	{
		fileName = name;
	}

	void startParse()
	{
		auto file = File(inFilePath);
	
		string text;

		while(!file.eof)
		{
			text ~= file.readln();
		}

		this.parse(text);
	}

	bool parse(string data)
	{
		data = replaceAll(data, regex(`\/\/[^\n]*`), "");
		data = replaceAll(data, regex("\n|\t"), "");
		data = replaceAll(data, regex(`\s{2,}`), "");

		auto clesses = split(data, regex(`[@\}]`));

		if(clesses.length == 0)
		{
			throw new Exception("parse classes is failed, no class struct!!", data);
		}

		foreach(c; clesses)
		{
				auto symbolFlag = split(c, "{");
				
				if(symbolFlag.length == 2)
				{
					
					auto symbolAttr = split(symbolFlag[0], ":");
					
					if(symbolAttr.length != 2)
					{
						throw new Exception("parse symbol  attr is failed,  symbol missing :, " ~ symbolFlag[0]);
					}

					IdlBaseInterface idlInterface;

					switch(symbolAttr[0])
					{
						case SYMBOL_STRUCT:
							idlInterface  = new IdlParseStruct;
							break;

						case SYMBOL_INTERFACE:
							idlInterface = new IdlParseInterface;
							break;	

						default:
							throw new Exception("parse symbol attr is error,  symbol: " ~ symbolAttr[0]);
					}
					
				if(idlInterface.parse(fileName, symbolAttr[1], symbolFlag[1]))
					{
						switch(symbolAttr[0])
						{
							case SYMBOL_STRUCT:
								idlStructList[idlInterface.getName] = cast(IdlParseStruct)idlInterface;
								break;

							case SYMBOL_INTERFACE:
								idlInerfaceList[idlInterface.getName] = idlInterface;
								break;

							default:
								throw new Exception("parse symbol attr is error,  symbol: " ~ symbolAttr[0]);
						}
					}
			}
		}

		this.create_code();
		return true;
	}


	void create_code()
	{
		string serverCodeInterface, serverCodeService;
		string clientCodeInterface, clientCodeService;
		string structCode;
		string flatbufferIdlCode;

		auto serverInterfaceStrings = appender!string();
		formattedWrite(serverInterfaceStrings, "module kissrpc.generated.%sInterface;\n\n", fileName);
		formattedWrite(serverInterfaceStrings, "import kissrpc.generated.%sMessage;\n", fileName);
		formattedWrite(serverInterfaceStrings, "import kissrpc.generated.%sService;\n\n", fileName);



		formattedWrite(serverInterfaceStrings, "import kissrpc.RpcServer;\n");
		formattedWrite(serverInterfaceStrings, "import kissrpc.RpcServerImpl;\n");
		formattedWrite(serverInterfaceStrings, "import kissrpc.RpcResponse;\n");
		formattedWrite(serverInterfaceStrings, "import kissrpc.RpcRequest;\n");
		formattedWrite(serverInterfaceStrings, "import flatbuffers;\n");

		auto server_service_strings = appender!string();
		formattedWrite(server_service_strings, "module kissrpc.generated.%sService;\n\n", fileName);
		formattedWrite(server_service_strings, "import kissrpc.generated.%sInterface;\n", fileName);
		formattedWrite(server_service_strings, "import kissrpc.generated.%sMessage;\n\n", fileName);
		formattedWrite(server_service_strings, "import kissrpc.RpcServer;\n");
		formattedWrite(server_service_strings, "import kissrpc.Unit;\n\n");

		auto client_interface_strings = appender!string();
		formattedWrite(client_interface_strings, "module kissrpc.generated.%sInterface;\n\n", fileName);
		formattedWrite(client_interface_strings, "import kissrpc.generated.%sMessage;\n", fileName);
		formattedWrite(client_interface_strings, "import kissrpc.generated.%sService;\n\n", fileName);

		formattedWrite(client_interface_strings, "import kissrpc.RpcRequest;\n");
		formattedWrite(client_interface_strings, "import kissrpc.RpcClientImpl;\n");
		formattedWrite(client_interface_strings, "import kissrpc.RpcClient;\n");
		formattedWrite(client_interface_strings, "import kissrpc.RpcResponse;\n");
		formattedWrite(client_interface_strings, "import kissrpc.Unit;\n");
		formattedWrite(client_interface_strings, "import flatbuffers;\n");


		auto client_service_strings = appender!string();
		formattedWrite(client_service_strings, "module kissrpc.generated.%sService;\n\n\n", fileName);
		formattedWrite(client_service_strings, "import kissrpc.generated.%sInterface;\n", fileName);
		formattedWrite(client_service_strings, "import kissrpc.generated.%sMessage;\n\n", fileName);
		formattedWrite(client_service_strings, "import kissrpc.RpcClient;\n");
		formattedWrite(client_service_strings, "import kissrpc.Unit;\n\n");



		auto struct_strings = appender!string();
		formattedWrite(struct_strings, "module kissrpc.generated.%sMessage;\n", fileName);
		formattedWrite(struct_strings, "import std.typetuple;\n\n\n");
	


		foreach(k, v; idlInerfaceList)
		{
			serverCodeInterface ~= v.createServerCodeForInterface(CODE_LANGUAGE.CL_DLANG);
			serverCodeService ~= v.createServerCodeForService(CODE_LANGUAGE.CL_DLANG);

			clientCodeInterface ~= v.createClientCodeForInterface(CODE_LANGUAGE.CL_DLANG);
			clientCodeService ~= v.createClientCodeForService(CODE_LANGUAGE.CL_DLANG);
		}

		foreach(k, v; idlStructList)
		{
			structCode ~= v.createCodeForLanguage(CODE_LANGUAGE.CL_DLANG);
		}

		foreach(k,v; idlStructList)
		{
			flatbufferIdlCode ~= IdlFlatbufferCode.createFlatbufferCode(v);
		}


		auto flatbuffer_strings = appender!string();


		auto modulePath = split(fileName, ".");

		// if(modulePath.length > 1)
		// {
		// 	for(int i = 0; i < modulePath.length-1; ++i)
		// 	{
		// 		outFilePath ~= ("/" ~ modulePath[i]);
		// 		if(!exists(outFilePath)) {
		// 			rmdir(outFilePath);
		// 		}
		// 		mkdir(outFilePath);
		// 		moduleFilePath ~= (modulePath[i] ~ ".");
		// 	}
			
		// 	fileName = modulePath[modulePath.length-1];
		
		// 	formattedWrite(flatbuffer_strings, "namespace kissrpc.generated.%smessage;\n\n", moduleFilePath);
		// 	formattedWrite(serverInterfaceStrings, "import kissrpc.generated.%smessage.%s;\n\n", moduleFilePath, fileName);
		// 	formattedWrite(client_interface_strings, "import kissrpc.generated.%smessage.%s;\n\n", moduleFilePath, fileName);
		// }else
		// {
		// 	formattedWrite(flatbuffer_strings, "namespace kissrpc.generated.message.hakar;\n\n");
		// 	formattedWrite(serverInterfaceStrings, "import kissrpc.generated.message.%s;\n\n",fileName);
		// 	formattedWrite(client_interface_strings, "import kissrpc.generated.message.%s;\n\n", fileName);
		// }



		if (!exists(outFilePath ~ "/kissrpc/")) {
			mkdir(outFilePath ~ "/kissrpc/");
		}
		outFilePath ~= "/kissrpc";

		if (!exists(outFilePath ~ "/generated")) {
			mkdir(outFilePath ~ "/generated");
		}
		outFilePath ~= "/generated";


		formattedWrite(flatbuffer_strings, "namespace kissrpc.generated.message;\n\n");
		formattedWrite(serverInterfaceStrings, "import kissrpc.generated.message.%s;\n\n",fileName);
		formattedWrite(client_interface_strings, "import kissrpc.generated.message.%s;\n\n", fileName);


		
		//generated server
		if(!exists(outFilePath ~ "/server/"))
		{
			mkdir(outFilePath ~ "/server/");
		}
		auto file = File(outFilePath ~ "/server/" ~ fileName ~ "Interface.d", "w+");
		file.write(serverInterfaceStrings.data ~ serverCodeInterface);
		file.close();


		file = File(outFilePath ~ "/server/" ~ fileName ~ "Service.d", "w+");
		file.write(server_service_strings.data ~ serverCodeService);
		file.close();


		//generated client
		if(!exists(outFilePath ~ "/client/"))
		{
			mkdir(outFilePath ~ "/client/");
		}

		file = File(outFilePath ~ "/client/" ~ fileName ~ "Interface.d", "w+");
		file.write(client_interface_strings.data ~ clientCodeInterface);
		file.close();

		file = File(outFilePath ~ "/client/" ~ fileName ~ "Service.d", "w+");
		file.write(client_service_strings.data ~ clientCodeService);
		file.close();
		


		//generated message
		if(!exists(outFilePath ~ "/message/"))
		{
			mkdir(outFilePath ~ "/message/");
		}

		file = File(outFilePath ~ "/message/" ~ fileName ~ "Message.d", "w+");
		file.write(struct_strings.data ~ structCode);
		file.close();


		file = File(outFilePath ~ "/message/" ~ fileName ~ ".fbs", "w+");
		file.write(flatbuffer_strings.data ~ flatbufferIdlCode);

		spawnProcess(["flatc", "-d", "-b", outFilePath ~ "/message/" ~ fileName ~ ".fbs", "--gen-onefile"],
			std.stdio.stdin, std.stdio.stdout, std.stdio.stderr, null, Config.none, outFilePath ~ "/message/");
		
		
		
		new Thread({
			Thread.sleep(2000.msecs); 
			auto b = std.file.read(outFilePath ~ "/message/" ~ fileName ~ ".d");
			
			string bb = cast(string)b;
			file = File(outFilePath ~ "/message/" ~ fileName ~ ".d", "w+");
			
			auto apstring = appender!string();
			formattedWrite(apstring, "module kissrpc.generated.message.%s;\n\n%s", fileName,bb);
			file.write(apstring.data);
			file.close();

		}).start();



	}

private:
	IdlBaseInterface[string] idlInerfaceList;

	string inFilePath = ".";
	string outFilePath = ".";
	string fileName;
	string moduleFilePath;
}

