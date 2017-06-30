module KissRpc.logs;

import KissRpc.unit;

import std.string;
import std.format;
import std.stdio;
import std.array : appender;
import std.file;
import std.experimental.logger;


immutable string PRINT_COLOR_NONE  = "\033[m";
immutable string PRINT_COLOR_RED   =  "\033[0;32;31m";
immutable string PRINT_COLOR_GREEN  = "\033[0;32;32m";
immutable string PRINT_COLOR_YELLOW = "\033[0;33m";

FileLogger log_file = null;

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

bool set_output_log_path(string file_path)
{
	log_file = new FileLogger(file_path);

	if(!log_file.file.isOpen)
	{
		log_file = null;
		log_error("log file is not open!!, file path:%s", log_file);

		return false;
	}

	return true;
}


void output_log(LOG_LEVEL type, string log_text)
{
		switch(type)
		{
			case LOG_LEVEL.LL_ERROR, LOG_LEVEL.LL_FATAL, LOG_LEVEL.LL_CRITICAL: 
				log_file.fatal(log_text);
				break;
				
			case LOG_LEVEL.LL_INFO: log_file.info(log_text); break;
				
			case LOG_LEVEL.LL_WARNING: log_file.warning(log_text); break;
				
			case LOG_LEVEL.LL_DEBUG: log_file.trace(log_text); break;

			default:break;
		}
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

		if(log_file !is null)
		{
			output_log(type, msg);
		}else
		{
			string out_info = format("%s [%s] %s:%s %s", prior, type, time_prior, msg, suffix);
			writeln(out_info);
		}

	}
	else
	{
		

		if(type == LOG_LEVEL.LL_ERROR || type == LOG_LEVEL.LL_FATAL ||  type == LOG_LEVEL.LL_CRITICAL)
		{
			if(log_file !is null)
			{
				output_log(msg, type);
			}else
			{
				string out_info = format("[%s] %s:%s ", type, time_prior, msg);

				win_writeln(out_info , FOREGROUND_RED);
			}

		}
		else if(type == LOG_LEVEL.LL_WARNING || type == LOG_LEVEL.LL_INFO)
		{
			if(log_file !is null)
			{
				output_log(msg, type);
			}else
			{
				string out_info = format("[%s] %s:%s ", type, time_prior, msg);
				win_writeln(out_info , FOREGROUND_GREEN);
			}

		}
		else
		{
			if(log_file !is null)
			{
				output_log(msg, type);
			}else
			{
				string out_info = format("[%s] %s:%s ", type, time_prior, msg);
				win_writeln(out_info , FOREGROUND_GREEN);
			}
		}
	}
	
}


version(onyxLog)
{
	import onyx.log;
	import onyx.bundle;
	import core.sys.windows.winbase;
	
	__gshared Log g_log;
	
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
	void kiss_log_debug(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_DEBUG , file , line);
	}
	void kiss_log_info(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_INFO , file , line);
	}
	void kiss_log_warning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_WARNING , file , line);
	}
	void kiss_log_error(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_ERROR ,  file , line);
	}
	void kiss_log_critical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_CRITICAL , file , line);
	}
	void kiss_log_fatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , LOG_LEVEL.LL_FATAL ,  file , line);
	}
	
}

void log_format(T ...)(T args, const LOG_LEVEL level)
{
	auto strings = appender!string();
	formattedWrite(strings, args);
	auto info = strings.data;
	
	switch(level)
	{
		case LOG_LEVEL.LL_INFO: kiss_log_info(info); break;
		case LOG_LEVEL.LL_WARNING: kiss_log_warning(info); break;
		case LOG_LEVEL.LL_DEBUG: kiss_log_debug(info); break;
		case LOG_LEVEL.LL_ERROR: kiss_log_error(info); break;
		case LOG_LEVEL.LL_CRITICAL: kiss_log_critical(info); break;
		case LOG_LEVEL.LL_FATAL: kiss_log_fatal(info); break;
			
		default: 
			kiss_log_info(info);
	}
}

void log_format_debug(T ...)(T args)
{
	log_format(args, LOG_LEVEL.LL_DEBUG);
}

void log_format_info(T ...)(T args)
{
	log_format(args, LOG_LEVEL.LL_INFO);
}

void log_format_warning(T ...)(T args)
{
	log_format(args, LOG_LEVEL.LL_WARNING);
}

void log_format_error(T ...)(T args)
{
	log_format(args, LOG_LEVEL.LL_ERROR);
}

void log_format_critical(T ...)(T args)
{
	log_format(args, LOG_LEVEL.LL_CRITICAL);
}
	
void log_format_fatal(T ...)(T args)
{
	log_format(args, LOG_LEVEL.LL_FATAL);
}

version(rpc_debug)
{
	alias de_writefln = log_format_debug;
	alias de_writeln = log_format_debug;
}else
{
	void null_log(T ...)(T args)
	{

	}
//	alias de_writefln = log_format_debug;
//	alias de_writeln = log_format_debug;
	alias de_writefln = null_log;
	alias de_writeln = null_log;
}

version(ultra_high)
{
	void null_log(T ...)(T args)
	{
		
	}

	alias log_info = null_log;
	alias log_warning = null_log;
	alias log_error = null_log;
	alias log_critical = null_log;
	alias log_fatal = null_log;
}else
{
	alias log_info = log_format_info;
	alias log_warning = log_format_warning;
	alias log_error = log_format_error;
	alias log_critical = log_format_critical;
	alias log_fatal = log_format_fatal;
}



unittest
{
	import KissRpc.logs;

	set_output_log_path("./info.log");



	log_format_debug("debug");
	log_info("info");
	log_error("errro");
	
}