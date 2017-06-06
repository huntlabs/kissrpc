module java.io.IOException;

final class IOException : Exception
{
	this(string msg, string file=__FILE__, size_t line=__LINE__, Throwable next=null) pure nothrow @nogc @safe
	{
		super(msg, file, line, next);
	}
}
