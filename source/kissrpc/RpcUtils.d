

module kissrpc.RpcUtils;

import std.experimental.logger.core;
import std.bitmanip;


class RpcUtils {
    static bool readBytes(T)(ubyte[] data, ref uint pos, ref T t) {
        if (data.length - pos < t.sizeof) {
            log("readBytes len less!!!");
            return false;
        }
        ubyte[t.sizeof] tmp;
        tmp[0 .. t.sizeof] = data[pos .. pos+t.sizeof];
        t = bigEndianToNative!(T)(tmp);
        pos += t.sizeof;
        return true;
    }
    static bool readString(ubyte[] data, ref uint pos, ushort msgLen,ref string s) {
        if (data.length - pos < msgLen) {
            log("readString len less!!!");
            return false;
        }
        ubyte[] tmp;
        tmp.length = msgLen;
        tmp[0 .. msgLen] = data[pos .. pos+msgLen];
        pos += msgLen;
        s = cast(string)tmp;
        return true;
    }

    static bool writeBytes(T)(ref ubyte[] data, T t) {
        ubyte[] tmp = nativeToBigEndian!(T)(t);
        foreach(value; tmp) {
            data ~= value;
        }
        return true;
    }
}