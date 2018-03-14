

module Parse;

import std.file;
import std.stdio;
import std.regex;
import std.string;
import std.algorithm.searching;
import std.experimental.logger;

static enum string ModuelTag = "module";
static enum string MessageTag = "message";
static enum string ServiceTag = "service";
static enum string EndTag = ";";
static enum string BlankTag = " ";
static enum string BeginContentTag = "{";
static enum string EndContentTag = "}";
static enum string BeginMessage = "(";
static enum string EndMessage = ")";


enum ParamType {
    BOOL = 0,
    BYTE, 
    UBYTE,
    SHORT,
    USHORT,
    INT,
    UINT,
    LONG,
    ULONG,
    FLOAT,
    DOUBLE,
    CHAR,
    STRING,
    MODULE,
    MESSAGE,
    SERVICE,
};

enum ParamType[string] ParamTypeTag = [
    "bool" : ParamType.BOOL, 
    "byte" : ParamType.BYTE, 
    "ubyte" : ParamType.UBYTE, 
    "short" : ParamType.SHORT, 
    "ushort" : ParamType.USHORT, 
    "int" : ParamType.INT, 
    "uint" : ParamType.UINT, 
    "long" : ParamType.LONG, 
    "ulong" : ParamType.ULONG, 
    "float" : ParamType.FLOAT, 
    "double" : ParamType.DOUBLE, 
    "char" : ParamType.CHAR, 
   "string" :  ParamType.STRING, 
];


enum ParamType[string] RpcTypeTag = [
    ModuelTag : ParamType.MODULE,
    MessageTag : ParamType.MESSAGE ,
    ServiceTag : ParamType.SERVICE,
];



struct ParamData {
    string paramTypeName;
    string name;
}

struct MessageData {
    ParamData[] params;
    string name;
}

struct InterfaceData {
    string name;
    string returnMessage;
    string paramMessage;
    string paramName;
}

struct ServiceData {
    string name;
    InterfaceData[] interfaces;
}


enum ParseStatus {
    Init = 0,
    MessageBegin,
    MessageContent,
    ServiceBegin,
    ServiceContent
}

class Parse {
public:
    this() {

    }
    bool doParse(string inputFile, string outputPath) {

        string buffer = cast(string)read(inputFile);

        buffer = replaceAll(buffer, regex("(\r)"), "");
        buffer = replaceAll(buffer, regex(";"), " ; ");
        buffer = replaceAll(buffer, regex("\\)"), " ) ");
        buffer = replaceAll(buffer, regex("\\("), " ( ");
        buffer = replaceAll(buffer, regex("\\{"), " { ");
        buffer = replaceAll(buffer, regex("\\}"), " } ");
        buffer = replaceAll(buffer, regex(" +"), " ");

        auto lines = split(buffer, "\n");
        _fullPath = outputPath;
        _status = ParseStatus.Init;
        foreach(k,v; lines) {
            if (!readLine(cast(int)k,v))
                return false;
        }        

        log("message ", _messages);
        log("service ", _services);

        if (!checkMessageValid())
            return false;
        log("checkMessageValid success");
        
        return true;
    }



private:
    bool readLine(int index, string line) {
        if (line.length == 0)
            return true;
        formatString(line);
        if (_status == ParseStatus.Init) {
            return doParseInit(index, line);
        }
        else if (_status == ParseStatus.MessageBegin || _status == ParseStatus.ServiceBegin) {
            return doParseBegin(index, line);
        }
        else if (_status == ParseStatus.MessageContent) {
            return doParseMessageContent(index, line);
        }
        else if (_status == ParseStatus.ServiceContent) {
            return doParseServiceContent(index, line);
        }

        return true;
    }

    bool doParseServiceContent(int index, string line) {

        string[] strs = split(line, EndTag);

        foreach(k,v; strs) {
            if (v == "")
                continue;
            string[] tags = split(v);
            if (k == strs.length - 1) {
                if (v.length == 1) {
                    if (v == EndContentTag) {
                        if (_curService.name != "") {
                            _services ~= _curService;
                            log("add service : ",_curService);
                        }
                        _status = ParseStatus.Init;
                        return true;
                    }
                    else {
                        log("tag end error = %s, error line = %s, string = %s".format(v, index, line));
                        return false;
                    }
                }
                else if (tags.length != 6 && tags.length != 4) {
                    log("interface tag count error , error line = %s, string = %s".format(index, line));
                    return false;
                }
            }
            if (tags.length == 6 || tags.length == 4) {
                InterfaceData data;
                data.returnMessage = tags[0];
                data.name = tags[1];
                if (tags.length == 6) {
                    if (tags[2] != BeginMessage || tags[5] != EndMessage) {
                        log("interface params need ( ) include params , error line = %s, string = %s".format(index, line));
                        return false;
                    }
                    data.paramMessage = tags[3];
                    data.paramName = tags[4];
                }
                else {
                    if (tags[2] != BeginMessage || tags[3] != EndMessage) {
                        log("interface params need ( ) include params , error line = %s, string = %s".format(index, line));
                        return false;
                    }
                }
                _curService.interfaces ~= data;
                log("add interface : ",data);
            }
            else {
                log("interface tag count error , error line = %s, string = %s".format(index, line));
                return false;
            }
        }
        return true;
    }

    bool doParseMessageContent(int index, string line) {
        string[] strs = split(line);
        int count = cast(int)(strs.length / 3);
        int left = strs.length % 3;
        if (left == 2) {
            log("tag count error, error line = %s, string = %s".format(index, line));
            return false;
        }

        for(int i = 0; i < count; i ++) {
            if (strs[i*3+2] != EndTag) {
                log("less ; , error line = %s, string = %s".format(index, line));
                return false;
            }
            ParamData param;
            param.paramTypeName = strs[i*3];
            param.name = strs[i*3+1];
            _curMsg.params ~= param;
            log("add param : ",_curMsg);
        }

        if (left == 1) {
            if (strs[$-1] != EndContentTag) {
                log("need } ,error tag = %s , error line = %s, string = %s".format(strs[$-1], index, line));
                return false;
            }
            if (_curMsg.name != "")
                _messages ~= _curMsg;
            _status = ParseStatus.Init;
            return true;
        }
        return true;
    }
    
    bool doParseBegin(int index, string line) {
        auto strs = split(line);
        if (strs.length == 0)
            return true;
        if (strs.length == 1 && strs[0] != BeginContentTag) {
            log("need '{' tag ,error line = %s, string = %s".format(index,line));
            return false;
        }
        if (strs.length == 1) {
            return true;
        } 
        string newStr = makeNewStr(strs, 1);
        if (_status == ParseStatus.MessageBegin) {
            _status = ParseStatus.MessageContent;
            return doParseMessageContent(index, newStr);
        }
        else {
             _status = ParseStatus.ServiceContent;
            return doParseServiceContent(index, newStr);
        }  
    }


    bool doParseInit(int index, string line) {
        auto strs = split(line);
        if (strs.length == 0)
            return true;


        if (strs.length == 1) {
            log("error line = %s, string = %s".format(index,line));
            return false;
        }
        if (!(strs[0] in RpcTypeTag)) {
            log("not support tag = %s, line = %s, string = %s".format(strs[0], index, line));
            return false;
        }
        ParamType Type = RpcTypeTag[strs[0]];
        if (Type == ParamType.MODULE) {
            if (strs.length != 3 || strs[2] != EndTag) {
                log("error endTag tag, line = %s, string = %s".format(index, line));
                return false;
            }
            doModule(strs[1]);
        }
        else {
            if (strs.length < 2) {
                log("less tag, line = %s, string = %s".format(index, line));
                return false;
            }
            if (strs.length == 3 && strs[2] != BeginContentTag) {
                log("error endTag tag, line = %s, string = %s".format(index, line));
                return false;
            }
            if (Type == ParamType.MESSAGE) {
                _curMsg = _curMsg.init;
                _curMsg.name = strs[1];
            }
            else {
                _curService = _curService.init;
                _curService.name = strs[1];
            }
            if (strs.length == 3) {
                _status = Type == ParamType.MESSAGE ? ParseStatus.MessageContent : ParseStatus.ServiceContent;
                return true;
            }
            else {
                _status = Type == ParamType.MESSAGE ? ParseStatus.MessageBegin : ParseStatus.ServiceBegin;
                string newStr = makeNewStr(strs, 2);
                return doParseBegin(index, newStr);
            }
        }
        return true;
    }


    void doModule(string name) {
        _moduleName = name;
        string[] dirs = split(_moduleName,".");
        foreach(value; dirs) {
            _fullPath ~= ("/"~value);
        }
        mkdirRecurse(_fullPath);
        log("module name = ", name);
    }


    void formatString(ref string str) {
        if (str.length == 0)
            return;
        if (str[0] == ' ')
            str = str[1..$];
        if (str[$-1] == ' ')
            str = str[0..$-1];
    }

    string makeNewStr(string[] strs, uint count) {
        if (count > strs.length)
            return "";
        string ret = "";
        for (uint i = count; i < strs.length; i ++) {
            ret ~= strs[i];
            if (i != strs.length -1)
                ret ~= " ";
        }
        return ret;
    }

    bool checkMessageValid() {
        if (!initAllMessageType()) {
            return false;
        }
        foreach(v1; _messages) {
            foreach(v2; v1.params) {
                if (!checkExsit(v2.paramTypeName))
                    return false;
            }
        }

        foreach(v1; _services) {
            foreach(v2; v1.interfaces) {
                if (!checkExsit(v2.returnMessage, true))
                    return false;
                if (v2.paramMessage != "") {
                    if (!checkExsit(v2.paramMessage))
                        return false;
                }
            }
        }
        return true;
    }


    bool initAllMessageType() {
        _msgTable = _msgTable.init;
        foreach(value; _messages) {
            if (value.name == "") {
                log("message name must not empty");
                return false;
            }
            if (value.name in _msgTable) {
                log("repeat message type = %s ".format(value.name));
                return false;
            }
            _msgTable[value.name] = value;
        }
        return true;
    }
    string getBaseType(string str) {
        if (str.length > 2 && str[$-2] == '[' && str[$-1] == ']') {
            return str[0..$-2];
        }
        return str;
    }
    bool checkExsit(string str, bool checkVoid = false) {
        string rType = getBaseType(str);
        if (!(rType in _msgTable) && !(rType in ParamTypeTag)) {
            if (checkVoid) {
                if (rType != "void") {
                    log("error message type = %s".format(str));
                    return false;
                }
            }
            else {
                log("error message type = %s".format(str));
                return false;
            }
        }
        return true;
    }



private:
    string _fullPath;
    string _moduleName;
    ParseStatus _status;
    ServiceData[] _services;
    MessageData[] _messages;
    MessageData _curMsg;
    ServiceData _curService;
    MessageData[string] _msgTable;
}




 
