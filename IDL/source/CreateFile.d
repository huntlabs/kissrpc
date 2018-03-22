



module CreateFile;

import Constant;

import std.file;
import std.stdio;
import std.typecons : tuple;
import std.process;
import std.experimental.logger;
import std.uni;
import std.string;
import std.regex;


class CreateFile {
public:
    this(ServiceData[] services, MessageData[] messages, string moduleName, string path) {
        _services = services;
        _messages = messages;
        _moduleName = "rpcgenerate."~moduleName;
        _fullPath = path;
        _path = path ~"/../";
        auto strs = split(moduleName,".");
        _moduleLast = strs[$-1];
        foreach(k,v; strs) {
            _fullPath ~= "/" ~ v;
        }
    }
    
    bool createFlatbufferFile() {

        log(_fullPath);
        log(_moduleLast);
	    mkdirRecurse(_fullPath);

        string fbsFile = _fullPath ~"/"~ _moduleLast ~ ".fbs";
        string buffer = "// automatically generated, do not modify\n";
        buffer ~= "namespace "~ _moduleName ~ ";\n\n";

        foreach(v1; _messages) {
            buffer ~= ("table " ~ v1.name ~ "Fb {\n");
            foreach(v2; v1.params) {
                string defaultValue = "";
                string paramTypeName = (v2.paramTypeName in ParamTypeTag) ? v2.paramTypeName : v2.paramTypeName~"Fb";
                string realType = v2.isArray ? "[" ~ paramTypeName ~ "]" : paramTypeName;
                if (v2.defaultValue != "") {
                    defaultValue = " = " ~ v2.defaultValue;
                }
                buffer ~= ("\t" ~ v2.name ~ ":" ~ realType ~ defaultValue ~";\n");
            }
            buffer ~= "}\n\n";
        }
        log("_messages = ",_messages);
        foreach(v1; _messages) {
            if (v1.isRootType)
                buffer ~= "root_type " ~ v1.name ~ "Fb;\n";
        }

        auto file = File(fbsFile, "w+");
		file.write(buffer);
		file.close();

        Pid pid;
        try {
            pid = spawnProcess(["flatc", "-d", "-o", _path,fbsFile]);
        }
        catch(Exception e) {
            log(e);
            return false;
        }
        scope(exit) {
            wait(pid);
            string packageBuffer = cast(string)read(_fullPath ~"/package.d");
            packageBuffer ~= "public import "~_moduleName~"."~_moduleLast~"Base;\n";
            packageBuffer ~= "public import "~_moduleName~"."~_moduleLast~"Stub;\n";
            File f;
            foreach(v1; _messages) {
                string fileName = _fullPath ~ "/" ~v1.name ~ "Fb.d";
                string buff = cast(string)read(fileName);
                string name = ""~ _moduleName ~"."~v1.name~"Fb;\n";
                packageBuffer ~= "public import "~name;
                buff =  "module "~ name ~ buff;
                f = File(fileName, "w+");
                f.write(buff);
                f.close();
            }
            f = File(_fullPath ~"/package.d","w+");
            f.write(packageBuffer);
            f.close();
        }
        return true;
    }

    bool createClassFile() {
        string classFile = _fullPath ~ "/" ~ _moduleLast ~ "Base.d";
        string buffer = "// automatically generated, do not modify\n";
        buffer~="module "~ _moduleName ~ "." ~_moduleLast~"Base;\n\n";

        foreach(v1; _services) {
            buffer ~= "class " ~ v1.name ~ " {\n";
            foreach(v2; v1.interfaces) {
                string paramsString = "";
                if (v2.paramMessage != "")
                    paramsString = v2.paramMessage ~ " " ~v2.paramName;
                buffer ~= "\tabstract "~v2.returnMessage ~ " "~v2.name ~ "("~paramsString~");\n";
            }
            buffer ~= "}\n\n";
        }

        foreach(v1; _messages) {
            buffer ~= "struct " ~ v1.name ~ " {\n";
            foreach(v2; v1.params) {
                string paramTypeName = v2.isArray ? v2.paramTypeName ~"[]" : v2.paramTypeName;
                string defaultValue = "";
                if (v2.defaultValue != "") {
                    if (v2.paramTypeName == "string") {
                        defaultValue = " = "~"\""~v2.defaultValue~"\"";
                    }
                    else {
                        defaultValue = " = "~v2.defaultValue;
                    }
                }
                buffer ~= "\t"~paramTypeName ~ " "~v2.name ~ defaultValue~";\n";
            }
            buffer ~= "}\n\n";
        }


        auto file = File(classFile, "w+");
		file.write(buffer);
		file.close();
        return true;
    }

    bool createClientStub() {

        foreach(v1; _services) {
            string file = _fullPath ~ "/" ~ v1.name ~ "Stub.d";
            string buffer = "// automatically generated, do not modify\n";
            buffer ~= "module "~ _moduleName ~ "." ~v1.name~"Stub;\n\n";
            buffer ~= "import "~_moduleName~"."~_moduleLast~"Base;\n";
            buffer ~= "import kissrpc.RpcConstant;\nimport kissrpc.RpcClient;\n\n";

            buffer ~= "final class "~v1.name~"Stub {\n";
            buffer ~= "public:\n";
            buffer ~= "\tthis(RpcClient client) {\n";
            buffer ~= "\t\t_rpcClient = client;\n";
            buffer ~= "\t}\n";

            foreach(v2; v1.interfaces) {
                bool hasReturn = v2.returnMessage != "" && v2.returnMessage != "void";
                bool hasParam = v2.paramMessage != "";
                buffer ~= "\tRpcResponseBody"~" "~v2.name~"("~makeSyncInterfaceParams(v2,hasParam,hasReturn)~") {\n";
                buffer ~= "\t\tRpcResponseBody response;\n";
                buffer ~= makeSyncCallString(v2,hasParam,hasReturn,v1.name);
                buffer ~= "\t\treturn response;\n";
                buffer ~= "\t}\n";
            }
            foreach(v2; v1.interfaces) {
                bool hasReturn = v2.returnMessage != "" && v2.returnMessage != "void";
                bool hasParam = v2.paramMessage != "";
                buffer ~= "\tvoid "~v2.name~"("~makeAsyncInterfaceParams(v2,hasParam,hasReturn)~") {\n";
                buffer ~= makeAsyncCallString(v2,hasParam,hasReturn,v1.name);
                buffer ~= "\t}\n";
            }

            
            buffer ~= "private:\n";
            buffer ~= "\tRpcClient _rpcClient;\n";
            buffer ~= "}\n";

            auto f = File(file, "w+");
            f.write(buffer);
            f.close();
        }
        return true;
    }

    string makeSyncInterfaceParams(InterfaceData data, bool hasParam, bool hasReturn) {
        if (hasParam && hasReturn) {
            return data.paramMessage~" "~data.paramName~", ref "~data.returnMessage ~" ret, ubyte[] exData";
        }
        else {
            if (hasParam)
                return data.paramMessage~" "~data.paramName~", ubyte[] exData";
            if (hasReturn)
                return "ref "~data.returnMessage~" ret, ubyte[] exData";
        }
        return "ubyte[] exData";
    }

    string makeAsyncInterfaceParams(InterfaceData data, bool hasParam, bool hasReturn) {
        string ret;
        if(hasParam)
            ret ~= data.paramMessage~" "~data.paramName~", ";
        if (hasReturn)
            ret ~= "ubyte[] exData, void delegate(RpcResponseBody response, " ~data.returnMessage~" ret";
        else 
            ret ~= "ubyte[] exData, void delegate(RpcResponseBody response";

        ret ~= ") func";
        return ret;
    }

    string makeSyncCallString(InterfaceData data, bool hasParam, bool hasReturn, string serviceName) {
        string ret;
        string tmp;

        if (hasParam)
            tmp = hasReturn ? (data.returnMessage ~", "~data.paramMessage) : ("void, "~data.paramMessage);
        else
            tmp = hasReturn ? data.returnMessage : "";
        
    
        ret ~= "\t\t";
        if (hasReturn)
            ret ~="ret = ";
        ret ~= "_rpcClient.call!("~tmp~")(\""~serviceName~"."~data.name~"\", response, exData";
        if (hasParam)
            ret ~= ", "~data.paramName;
        ret ~= ");\n";

        return ret;
    }
    string makeAsyncCallString(InterfaceData data, bool hasParam, bool hasReturn, string serviceName) {
        string ret = "\t\t_rpcClient.call!(";
        if (hasReturn && hasParam) {
            ret ~= data.returnMessage ~", "~data.paramMessage;
        }
        else {
            if (hasReturn)
                ret ~= data.returnMessage;
            if (hasParam)
                ret ~= data.paramMessage;
        }
        ret ~=")(\"" ~serviceName~"."~data.name~"\", exData, (RpcResponseBody response";
        if (hasReturn)
            ret ~= ", "~data.returnMessage~" ret";
        ret ~="){\n";
        if (hasReturn)
            ret ~= "\t\t\tfunc(response, ret);\n";
        else
            ret ~= "\t\t\tfunc(response);\n";
        ret ~= "\t\t}";
        if (hasParam)
            ret ~= ", "~data.paramName;
        ret ~= ");\n";
        return ret;
    }




private:
    ServiceData[] _services;
    MessageData[] _messages;
    string _moduleName;
    string _fullPath;
    string _path;
    string _moduleLast;
}


