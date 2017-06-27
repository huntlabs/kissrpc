module KissRpc.logs;

import kiss.util.Log;
import std.string;
import std.format;
import std.stdio;
import std.array : appender;


void log_format(T ...)(T args, const LOG_LEVEL level)
{
	auto strings = appender!string();
	formattedWrite(strings, args);
	auto info = strings.data;
	
	switch(level)
	{
		case LOG_LEVEL.LL_INFO: kiss.util.Log.log_info(info); break;
		case LOG_LEVEL.LL_WARNING: kiss.util.Log.log_warning(info); break;
		case LOG_LEVEL.LL_DEBUG: kiss.util.Log.log_debug(info); break;
		case LOG_LEVEL.LL_ERROR: kiss.util.Log.log_error(info); break;
		case LOG_LEVEL.LL_CRITICAL: kiss.util.Log.log_critical(info); break;
		case LOG_LEVEL.LL_FATAL: kiss.util.Log.log_fatal(info); break;
			
		default: 
			kiss.util.Log.log_info(info);
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

	alias de_writefln = log_format_debug;
	alias de_writeln = log_format_debug;
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