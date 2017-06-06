module java.nio.channels.WritableByteChannel;

import java.nio.ByteBuffer;

interface WritableByteChannel
{
	bool isOpen();
	void close();
	size_t write(ref ByteBuffer src);
}
