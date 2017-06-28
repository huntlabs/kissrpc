/*
 * Kiss - A simple base net library
 *
 * Copyright (C) 2017 Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module kiss.util.Log;

import std.string;
import std.stdio;
import std.datetime;
import std.conv;
import KissRpc.unit;

immutable string PRINT_COLOR_NONE  = "\033[m";
immutable string PRINT_COLOR_RED   =  "\033[0;32;31m";
immutable string PRINT_COLOR_GREEN  = "\033[0;32;32m";
immutable string PRINT_COLOR_YELLOW = "\033[0;33m";

enum LOG_LEVEL
{
	LL_INFO,
	LL_WARNING,
	LL_DEBUG,
	LL_ERROR,
	LL_CRITICAL,
	LL_FATAL,
}


//#define PRINT_COLOR_YELLOW 	   "\033[1;33m"
//#define PRINT_COLOR_BLUE         "\033[0;32;34m"
//#define PRINT_COLOR_WHITE        "\033[1;37m"
//#define PRINT_COLOR_CYAN         "\033[0;36m"
//#define PRINT_COLOR_PURPLE       "\033[0;35m"
//#define PRINT_COLOR_BROWN        "\033[0;33m"
//#define PRINT_COLOR_DARY_GRAY    "\033[1;30m"
//#define PRINT_COLOR_LIGHT_RED    "\033[1;31m"
//#define PRINT_COLOR_LIGHT_GREEN  "\033[1;32m"
//#define PRINT_COLOR_LIGHT_BLUE   "\033[1;34m"
//#define PRINT_COLOR_LIGHT_CYAN   "\033[1;36m"
//#define PRINT_COLOR_LIGHT_PURPLE "\033[1;35m"
//#define PRINT_COLOR_LIGHT_GRAY   "\033[0;37m"


version(Windows)
{
	import core.sys.windows.wincon;
	import core.sys.windows.winbase;
	import core.sys.windows.windef;

	__gshared HANDLE g_hout = null;

	void win_writeln(string msg , ushort color)
	{
		if(g_hout is null)
			g_hout = GetStdHandle(STD_OUTPUT_HANDLE);
		SetConsoleTextAttribute(g_hout , color);
		writeln(msg);
		SetConsoleTextAttribute(g_hout ,  FOREGROUND_BLUE|FOREGROUND_GREEN|FOREGROUND_RED);
	}

}

private string convTostr(string msg , string file , size_t line)
{
	import std.conv;
	return msg ~ " - " ~ file ~ ":" ~ to!string(line);	
}


void log_kiss(string msg , LOG_LEVEL type ,  string file = __FILE__ , size_t line = __LINE__)
{
	string time_prior = RPC_SYSTEM_TIMESTAMP_STR;

	version(Posix)
	{
		string prior;
		string suffix = PRINT_COLOR_NONE;

		if(type == LOG_LEVEL.LL_ERROR || type == LOG_LEVEL.LL_FATAL ||  type == LOG_LEVEL.LL_CRITICAL)
		{
			prior = PRINT_COLOR_RED;
		}
		else if(type == LOG_LEVEL.LL_INFO)
		{
			prior = PRINT_COLOR_GREEN;

		}else if(type == LOG_LEVEL.LL_WARNING)
		{
			prior = PRINT_COLOR_YELLOW;
		}

		string out_info = format("%s %s [%s] %s %s", prior, time_prior, type, msg, suffix);

		writeln(out_info);
	}
	else
	{

		string out_info = format("%s [%s] %s ",  time_prior, type, msg);

		if(type == LOG_LEVEL.LL_ERROR || type == LOG_LEVEL.LL_FATAL ||  type == LOG_LEVEL.LL_CRITICAL)
		{
			win_writeln(out_info , FOREGROUND_RED);
		}
		else if(type == LOG_LEVEL.LL_WARNING || type == LOG_LEVEL.LL_INFO)
		{
			win_writeln(out_info , FOREGROUND_GREEN);
		}
		else
		{
			writeln(out_info);
		}
	}

}


version(onyxLog)
{
	import onyx.log;
	import onyx.bundle;
	import core.sys.windows.winbase;

	__gshared Log g_log;

	bool load_log_conf(immutable string logConfPath)
	{
		if(g_log is null)
		{
			auto bundle = new immutable Bundle(logConfPath);
			createLoggers(bundle);
			g_log = getLogger("logger");
		}
		return true;
	}

	void log_debug(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null )
			g_log.debug_(convTostr(msg , file , line));
		log_kiss(msg , LOG_LEVEL.LL_DEBUG , file , line);
	}

	void log_info(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.info(convTostr(msg , file , line));
		log_kiss(msg , LOG_LEVEL.LL_INFO, file , line);
	}

	void log_warning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.warning(convTostr(msg , file , line));
		log_kiss(msg , LOG_LEVEL.LL_WARNING , file , line);
	}

	void log_error(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.error(convTostr(msg , file , line));
		log_kiss(msg , LOG_LEVEL.LL_ERROR , file , line);
	}

	void log_critical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.critical(convTostr(msg , file , line));
		log_kiss(msg , LOG_LEVEL.LL_CRITICAL , file , line);
	}

	void log_fatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.fatal(convTostr(msg , file , line));
		log_kiss(msg , LOG_LEVEL.LL_FATAL , file , line);
	}

}
else
{
	bool load_log_conf(immutable string logConfPath)
	{
		return true;
	}
	void log_debug(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_DEBUG , file , line);
	}
	void log_info(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_INFO , file , line);
	}
	void log_warning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_WARNING , file , line);
	}
	void log_error(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_ERROR ,  file , line);
	}
	void log_critical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_CRITICAL , file , line);
	}
	void log_fatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_FATAL ,  file , line);
	}

}

unittest
{
	import kiss.util.Log;
	
	load_log_conf("default.conf");
	
	log_debug("debug");
	log_info("info");
	log_error("errro");

}