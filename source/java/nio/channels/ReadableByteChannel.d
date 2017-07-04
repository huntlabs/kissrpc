module java.nio.channels.ReadableByteChannel;

import java.nio.ByteBuffer;

interface ReadableByteChannel
{
	bool isOpen();
	void close();
	size_t read(ref ByteBuffer dst);
}
