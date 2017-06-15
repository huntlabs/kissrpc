module app;

import IDL.idl_parse;

void main()
{
	auto idl = new idl_parse;

	idl.parse("    @message:user_info //类型结构
    {
        string phone:3;
        string user_name:1;
        int age:2;
        double wiget:4;
    }

    @service:hello //接口类
    {
        sync: string func_name_sync(string msg, int i, double d); //同步
        async: string func_name_async(string msg, int i, double d); //异步
        sync: user_info query_user_info(string name); //同步调用返回结构化参数
        sync: void save_user_info(string name, user_info info, int num, user_info user);
    }");

}