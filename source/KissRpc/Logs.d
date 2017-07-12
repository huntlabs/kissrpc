module KissRpc.Logs;

import KissRpc.Unit;

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

FileLogger logFile = null;

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

bool setOutputLogPath(string filePath)
{
	logFile = new FileLogger(filePath);

	if(!logFile.file.isOpen)
	{
		logFile = null;
		logError("log file is not open!!, file path:%s", logFile);

		return false;
	}

	return true;
}


void outputLog(LOG_LEVEL type, string logText)
{
		switch(type)
		{
			case LOG_LEVEL.LL_ERROR, LOG_LEVEL.LL_FATAL, LOG_LEVEL.LL_CRITICAL: 
				logFile.fatal(logText);
				break;
				
			case LOG_LEVEL.LL_INFO: logFile.info(logText); break;
				
			case LOG_LEVEL.LL_WARNING: logFile.warning(logText); break;
				
			case LOG_LEVEL.LL_DEBUG: logFile.trace(logText); break;

			default:break;
		}
}

void logKiss(string msg , LOG_LEVEL type ,  string file = __FILE__ , size_t line = __LINE__)
{
	string timePrior = RPC_SYSTEM_TIMESTAMP_STR;
	
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

		if(logFile !is null)
		{
			outputLog(type, msg);
		}else
		{
			string outInfo = format("%s [%s] %s:%s %s", prior, type, timePrior, msg, suffix);
			writeln(outInfo);
		}

	}
	else
	{
		

		if(type == LOG_LEVEL.LL_ERROR || type == LOG_LEVEL.LL_FATAL ||  type == LOG_LEVEL.LL_CRITICAL)
		{
			if(logFile !is null)
			{
				outputLog(msg, type);
			}else
			{
				string outInfo = format("[%s] %s:%s ", type, timePrior, msg);

				win_writeln(outInfo , FOREGROUND_RED);
			}

		}
		else if(type == LOG_LEVEL.LL_WARNING || type == LOG_LEVEL.LL_INFO)
		{
			if(logFile !is null)
			{
				outputLog(msg, type);
			}else
			{
				string outInfo = format("[%s] %s:%s ", type, timePrior, msg);
				win_writeln(outInfo , FOREGROUND_GREEN);
			}

		}
		else
		{
			if(logFile !is null)
			{
				outputLog(msg, type);
			}else
			{
				string outInfo = format("[%s] %s:%s ", type, timePrior, msg);
				win_writeln(outInfo , FOREGROUND_GREEN);
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
		logKiss(msg , LOG_LEVEL.LL_DEBUG , file , line);
	}
	
	void logInfo(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.info(convTostr(msg , file , line));
		logKiss(msg , LOG_LEVEL.LL_INFO, file , line);
	}
	
	void logWarning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.warning(convTostr(msg , file , line));
		logKiss(msg , LOG_LEVEL.LL_WARNING , file , line);
	}
	
	void logError(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.error(convTostr(msg , file , line));
		logKiss(msg , LOG_LEVEL.LL_ERROR , file , line);
	}
	
	void logCritical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.critical(convTostr(msg , file , line));
		logKiss(msg , LOG_LEVEL.LL_CRITICAL , file , line);
	}
	
	void logFatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.fatal(convTostr(msg , file , line));
		logKiss(msg , LOG_LEVEL.LL_FATAL , file , line);
	}
	
}
else
{
	void kissLogDebug(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		logKiss(msg , LOG_LEVEL.LL_DEBUG , file , line);
	}
	void kissLogInfo(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		logKiss(msg , LOG_LEVEL.LL_INFO , file , line);
	}
	void kissLogWarning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		logKiss(msg , LOG_LEVEL.LL_WARNING , file , line);
	}
	void kissLogError(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		logKiss(msg , LOG_LEVEL.LL_ERROR ,  file , line);
	}
	void kissLogCritical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		logKiss(msg , LOG_LEVEL.LL_CRITICAL , file , line);
	}
	void kissLogFatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		logKiss(msg , LOG_LEVEL.LL_FATAL ,  file , line);
	}
	
}

void logFormat(T ...)(T args, const LOG_LEVEL level)
{
	auto strings = appender!string();
	formattedWrite(strings, args);
	auto info = strings.data;
	
	switch(level)
	{
		case LOG_LEVEL.LL_INFO: kissLogInfo(info); break;
		case LOG_LEVEL.LL_WARNING: kissLogWarning(info); break;
		case LOG_LEVEL.LL_DEBUG: kissLogDebug(info); break;
		case LOG_LEVEL.LL_ERROR: kissLogError(info); break;
		case LOG_LEVEL.LL_CRITICAL: kissLogCritical(info); break;
		case LOG_LEVEL.LL_FATAL: kissLogFatal(info); break;
			
		default: 
			kissLogInfo(info);
	}
}

void logFormatDebug(T ...)(T args)
{
	logFormat(args, LOG_LEVEL.LL_DEBUG);
}

void logFormatInfo(T ...)(T args)
{
	logFormat(args, LOG_LEVEL.LL_INFO);
}

void logFormatWarning(T ...)(T args)
{
	logFormat(args, LOG_LEVEL.LL_WARNING);
}

void logFormatError(T ...)(T args)
{
	logFormat(args, LOG_LEVEL.LL_ERROR);
}

void logFormatCritical(T ...)(T args)
{
	logFormat(args, LOG_LEVEL.LL_CRITICAL);
}
	
void logFormatFatal(T ...)(T args)
{
	logFormat(args, LOG_LEVEL.LL_FATAL);
}

version(RpcDebug)
{
	alias deWritefln = logFormatDebug;
	alias deWriteln = logFormatDebug;
}else
{
	void nullLog(T ...)(T args)
	{

	}
//	alias deWritefln = logFormatDebug;
//	alias deWriteln = logFormatDebug;
	alias deWritefln = nullLog;
	alias deWriteln = nullLog;
}

version(UltraHigh)
{
	void nullLog(T ...)(T args)
	{
		
	}

	alias logInfo = nullLog;
	alias logWarning = nullLog;
	alias logError = nullLog;
	alias logCritical = nullLog;
	alias logFatal = nullLog;
}else
{
	alias logInfo = logFormatInfo;
	alias logWarning = logFormatWarning;
	alias logError = logFormatError;
	alias logCritical = logFormatCritical;
	alias logFatal = logFormatFatal;
}



unittest
{
	import KissRpc.Logs;
//
//	setOutputLogPath("./info.log");
//
//
	writeln("-------------------------------------------------------");
	logFormatDebug("debug");
	logInfo("info");
	logError("errro");
	
}
