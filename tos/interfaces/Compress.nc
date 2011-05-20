interface Compress {
	/* in - location of uncompressed text
	   out - where compressed text will be written
	   inLength - length of uncompressed text
	   outMaxLength - maximum allowable compressed text length
	   return - length of compressed text, or 0 if compression failed */
	command uint8_t compress(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength);

	command uint8_t chainCompress(uint8_t* prev, uint8_t* in, uint8_t* out, uint8_t prevLength, uint8_t inLength, uint8_t outMaxLength);
}
