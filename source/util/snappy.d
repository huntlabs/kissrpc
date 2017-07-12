module util.snappy;

import std.conv;

extern (C) {
  enum snappy_status {
    SNAPPY_OK = 0,
    SNAPPY_INVALID_INPUT = 1,
    SNAPPY_BUFFER_TOO_SMALL = 2,
  };

  snappy_status snappy_uncompressed_length(const byte* compressed,
                                           size_t compressed_length,
                                           size_t* result);

  snappy_status snappy_uncompress(const byte* compressed,
                                  size_t compressed_length,
                                  byte* uncompressed,
                                  size_t* uncompressed_length);
  snappy_status snappy_compress(const byte* input,
                                size_t input_length,
                                byte* compressed,
                                size_t* compressed_length);
  size_t snappy_max_compressed_length(size_t source_length);
}

class Snappy {
  
static byte[] uncompress(byte[] compressed) {
    size_t uncompressedPrediction;
    snappy_status ok = snappy_uncompressed_length(compressed.ptr, compressed.length, &uncompressedPrediction);
    if (ok != snappy_status.SNAPPY_OK) {
      throw new Exception(to!(string)(ok));
    }
    auto res = new byte[uncompressedPrediction];
    size_t uncompressed = uncompressedPrediction;
    ok = snappy_uncompress(compressed.ptr, compressed.length, res.ptr, &uncompressed);
    if (ok != snappy_status.SNAPPY_OK) {
      throw new Exception(to!(string)(ok));
    }
    if (uncompressed != uncompressedPrediction) {
      throw new Exception("uncompressedPrediction " ~ to!(string)(uncompressedPrediction) ~ " != " ~ "uncompressed " ~ to!(string)(uncompressed));
    }
    return res;
  }



  static byte[] compress(byte[] uncompressed) {
    size_t maxCompressedSize = snappy_max_compressed_length(uncompressed.length);
    byte[] res = new byte[maxCompressedSize];
    size_t compressedSize = maxCompressedSize;
    snappy_status ok = snappy_compress(uncompressed.ptr, uncompressed.length, res.ptr, &compressedSize);
    if (ok != snappy_status.SNAPPY_OK) {
      throw new Exception(to!(string)(ok));
    }
    return res[0..compressedSize];
  }

}


unittest{
	import std.stdio;
	import util.snappy;

	byte[] data = cast(byte[])"ffdsffffffffffffffffaaaaaaaaaaaaaaaaaaccccccccccccccccccccccccdddddddddddddddddddeeeeeeeeeeeeeeeeeeeeeee";
	writeln("-------------------------------------------------");
	writefln("start test compress data, length:%s", data.length);

	byte[] cprData = Snappy.compress(data);
	writefln("compress data, length:%s, data:%s", cprData.length, cprData);

	byte[] unData = Snappy.uncompress(cprData);
	writefln("uncompress data, length:%s, data:%s", unData.length, unData);
}