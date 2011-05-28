/**
 * ExpGolombCodebook16P.nc
 * Purpose: An adaptive codebook based on a hash table and the exponential
 * golomb code. Uses 512 bytes of RAM.
 * Author(s): Matthew Tan Creti
 *
 * Copyright 2011 Matthew Tan Creti
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

generic module ExpGolombCodebook16P() {
	provides {
		interface Codebook16;
		interface ChainCompressor;
	}
	uses {
		interface BitPacker;
	}
}
implementation {
	uint16_t codebook[255];

	command uint8_t ChainCompressor.encode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint8_t i;

		call BitPacker.init(out, outMaxLength);
		for (i=0; i<inLength; i+=2) {
			uint32_t code;
			uint8_t length;
			uint16_t in16;
			if (i+1 < inLength) {
				in16 = ((uint16_t)in[i]) + (in[i+1]<<8);
			} else {
				in16 = in[i];
			}
			length = call Codebook16.getCode(in16, &code);
			if (call BitPacker.pack32(code, length) == FAIL) return 0;
		}

		return call BitPacker.getLength();
	}

	command uint8_t ChainCompressor.decode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode
		return 0;
	}

	/**
	 * See ExpGolombCodebook8P, this is an extension for 16-bit inputs.
	 */
	command uint8_t Codebook16.getCode(uint16_t clear, uint32_t* code) {
		uint8_t depth;
		uint16_t propagate = clear;
		uint8_t prehash = clear ^ (clear>>8);
		/* default if clear is not found in codebook */
		uint8_t length = 16 + 8;
		*code = clear;

		/* search for clear in code book, while at same time inserting clear into codebook */
		for (depth=0; depth<8; depth++) {
			uint8_t offset = (1 << depth) - 1;
			uint8_t hash = (prehash % (offset + 1)) + offset;	
			uint16_t temp = codebook[hash];
			if (temp == clear) {
				*code = hash - offset + (1 << depth);
				length = 2*depth + 1;
				codebook[hash] = propagate;	
				break;
			}
			codebook[hash] = propagate;	
			propagate = temp;
		}

		return length;
	}
}
