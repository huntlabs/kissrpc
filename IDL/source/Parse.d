

module Parse;

import Constant;

import std.file;
import std.stdio;
import std.regex;
import std.string;
import std.algorithm.searching;
import std.experimental.logger;



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
        buffer = replaceAll(buffer, regex("="), " = ");
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

    ServiceData[] getServices() {
        return _services;
    }
    
    MessageData[] getMessages() {
        return _messages;
    }

    string getModule() {
        return _moduleName;
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
        else if (_status == ParseStatus.ServiceContent || _status == ParseStatus.MessageContent) {
            return doParseContent(index, line);
        }   
      
        return true;
    }

    bool doParseContent(int index, string line) {
        string[] strs = split(line, EndTag);
        foreach(k,v; strs) {
            if (v == "")
                continue;
            if (k == strs.length - 1) {
                int ret = checkEndTag(v, index, line);
                if (ret == 0) {
                    return true;
                }
                else if (ret == -1) {
                    return false;
                }
            }
            else {
                if (!parseSingleData(v, index, line))
                    return false;
            }
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
            return doParseContent(index, newStr);
        }
        else {
             _status = ParseStatus.ServiceContent;
            return doParseContent(index, newStr);
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
        else if (Type == ParamType.ROOTTYPE) {
            if (strs.length % 3 != 0) {
                log("error root_type tag count, line = %s, string = %s".format(index, line));
                return false;
            }
            for(int i; i < strs.length/3; i ++) {
                if (strs[i*3 + 2] != EndTag) {
                    log("error endTag tag = %s , line = %s, string = %s".format(strs[i*3 + 2],index, line));
                    return false;
                }
                if (strs[i*3] != RootTypeTag) {
                    log("need root_type tag not %s , line = %s, string = %s".format(strs[i*3],index, line));
                    return false;
                }
                if (strs[i*3+1] == "") {
                    log("root_type must not be empty, line = %s, string = %s".format(index, line));
                    return false;
                }
                _rootTypes ~= strs[i*3+1];
            }
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
        foreach(ref v1; _messages) {
            foreach(v2; v1.params) {
                if (!checkExsit(v2.paramTypeName))
                    return false;
            }
            foreach(v3; _rootTypes) {
                if (v1.name == v3)
                    v1.isRootType = true;
            }
        }
        foreach(v1; _rootTypes) {
            if (!(v1 in _msgTable)) {
                log("root_type = %s not found!!", v1);
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
        if (!(str in _msgTable) && !(str in ParamTypeTag)) {
            if (checkVoid) {
                if (str != "void") {
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

    //0: reach end tag '}' , -1: error end tag '}', 1: need parse normal data
    int checkEndTag(string str, int index, string line) {
        formatString(str);
        if (str.length == 1) {
            if (str == EndContentTag) {
                if (_status == ParseStatus.MessageContent) {
                    if (_curMsg.name != "") {
                        _messages ~= _curMsg;
                    }
                }
                else if (_status == ParseStatus.ServiceContent) {
                    if (_curService.name != "") {
                        _services ~= _curService;
                    }
                }
                else {
                    log("error status when checkEndTag = %s, error line = %s, string = %s".format(_status, index, line));
                    return false;
                }
                _status = ParseStatus.Init;
                return 0;
            }
            else {
                log("tag end error = %s, error line = %s, string = %s".format(str, index, line));
                return -1;
            }
        }
        return 1;
    }

    bool parseSingleData(string str, int index, string line) {
        string[] strs = split(str);
        if (_status == ParseStatus.MessageContent) {
            if (strs.length != 2 && strs.length != 4) {
                log("tag count error = %s need = 2 or 4 , error line = %s, string = %s".format(strs.length, index, line));
                return false;
            }
        }
        else if (_status == ParseStatus.ServiceContent) {
            if (strs.length != 4 && strs.length != 6) {
                log("tag count error = %s need = 4 or 6 , error line = %s, string = %s".format(strs.length, index, line));
                return false;
            }
        }
        else {
            log("error status when parseSingleData, error line = %s, string = %s".format(index, line));
            return false;
        }
        bool ret;
        if (_status == ParseStatus.MessageContent) {
            ret = parseSingleParams(strs, index, line);
        }
        else {
            ret = parseSingleFunction(strs, index, line);
        }

        return ret;
    }

    bool parseSingleParams(string[] strs, int index, string line) {
        ParamData param;
        param.paramTypeName = getBaseType(strs[0]);
        param.isArray = param.paramTypeName != strs[0];
        param.name = strs[1];
        if (strs.length > 2) {
            if (strs[2] != EqualTag) {
                log("error tag = %s need '=' , error line = %s, string = %s".format(strs[2],index, line));
                return false;
            }
            param.defaultValue = replaceAll(strs[3],regex("\""),"");
        }
        _curMsg.params ~= param;
        writeln("message %s add param %s".format(_curMsg.name, _curMsg));
        return true;
    }

    bool parseSingleFunction(string[] strs, int index, string line) {
        InterfaceData data;
        data.returnMessage = strs[0];
        data.name = strs[1];
        if (strs[2] != BeginMessageTag) {
            log("interface params need ( include params , error line = %s, string = %s".format(index, line));
            return false;
        }
        int checkIndex;
        if (strs.length > 4) {
            data.paramMessage = strs[3];
            data.paramName = strs[4];
            checkIndex = 5;
        }
        else {
            checkIndex = 3;
        }
        if (strs[checkIndex] != EndMessageTag) {
            log("interface params need ) include params , error line = %s, string = %s".format(index, line));
            return false;
        }
        _curService.interfaces ~= data;
        writeln("interface %s add function %s".format(_curService.name, data));
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
    string[] _rootTypes;
}




 
