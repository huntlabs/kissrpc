

module kissrpc.RpcConstant;




enum RpcEvent {
    Close = 0, //对方已关闭
    WriteFailed = 1, //写失败
    HeadParseError = 2, //RPC 头解析失败
    BodyParseError = 3, //RPC Body解析失败
    ConnectFailed = 4, //连接失败
    ConnectSuccess = 5, //连接成功
    NotFoundCallBack = 6,  //未找到回调reqId
    NewClientCome = 7, //有客户端新连接
}

//传输协议
enum RpcProtocol {
    MessagePack = 0, 
    FlatBuffer = 1,
    Http = 2,
    Max = 3,
}

//压缩类型
enum RpcCompress {
    None = 0,
    Snappy = 1,
    Max = 2,
}

//响应状态码
enum RpcProcCode {
    Success = 0,       //成功
    DecodeFailed,      //解码失败
    EncodeFailed,      //编码失败
    NoFunctionName,    //未找到方法
    ParamsCountError,  //参数个数错误(暂时只支持1个)
    FunctionError,     //方法执行异常
    SendFailed,        //发送失败
    SendTimeout,       //发送超时
    ConnectClosed,     //连接断开
};





//Rpc消息头定义
struct RpcHeadData {
    ushort rpcVersion;  //rpc版本号
    ushort key;          //key 
    ushort secret;       //秘钥 
    ubyte compress;     //压缩类型
    ubyte protocol;     //数据协议 RpcProtocol
    ushort exDataLen;   //附加数据长度
    ubyte msgLen;       // request: 消息体名,接口名长度 response : error msg
    ushort dataLen;     //消息体数据长度 
    ulong clientSeqId;   //客户端消息队列ID
    ubyte code;         //服务器返回code
}


//Rpc请求消息体数据
struct RpcContentData {
    ubyte[] exData;  //附加数据
    ubyte[] data;  //接口参数
    string msg;  //when request msg means rpc function name, when response msg means process msg
}


//Rpc请求返回数据
struct RpcResponseBody {
    int code;   //RpcProcCode
    string msg;
    ubyte[] exData;
}



const ushort RPC_VERSION = 1;
const ushort RPC_KEY = 123;
const ushort RPC_SECRET = 123;



