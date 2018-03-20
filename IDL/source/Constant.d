

module Constant;

static enum string ModuelTag = "module";
static enum string MessageTag = "message";
static enum string ServiceTag = "service";
static enum string EndTag = ";";
static enum string BlankTag = " ";
static enum string BeginContentTag = "{";
static enum string EndContentTag = "}";
static enum string BeginMessageTag = "(";
static enum string EndMessageTag = ")";
static enum string EqualTag = "=";
static enum string RootTypeTag = "root_type";


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
    ROOTTYPE
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
    RootTypeTag : ParamType.ROOTTYPE,
];



struct ParamData {
    string paramTypeName;
    string name;
    string defaultValue;
    bool isArray;
}

struct MessageData {
    ParamData[] params;
    string name;
    bool isRootType;
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
