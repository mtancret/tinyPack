/**
 * ExpGolombCodebook8P.nc
 * Purpose: An adaptive codebook based on a hash table and the exponential
 * golomb code. Requires only 15 bytes of RAM.
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

generic module ExpGolombCodebook8P() {
	provides {
		interface Codebook8;
		interface ChainCompressor;
	}
	uses {
		interface BitPacker;
	}
}
implementation {
	uint8_t codebook[15];

	command uint8_t ChainCompressor.encode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint8_t i;

		call BitPacker.init(out, outMaxLength);
		for (i=0; i<inLength; i++) {
			uint16_t code;
			uint8_t length = call Codebook8.getCode(in[i], &code);
			if (call BitPacker.pack16(code, length) == FAIL) return 0;
		}

		return call BitPacker.getLength();
	}

	command uint8_t ChainCompressor.decode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode
		return 0;
	}

	/**
	* Example of codebook. The code depends on the index at which the
	* clear is found. If the clear is not found the code is
	* [0000 8-bit-clear].
	*
	*  index => code
	*  0 => 1          depth=0, offset=0
	*
	*  1 => 0 1 0      depth=1, offset=1
	*  2 => 0 1 1
	*
	*  3 => 00 1 00    depth=2, offset=3
	*  4 => 00 1 01
	*  5 => 00 1 10
	*  6 => 00 1 11
	*
	*  7 => 000 1 000  depth=3, offset=7
	*  8 => 000 1 001
	*  9 => 000 1 010
	* 10 => 000 1 011
	* 11 => 000 1 100
	* 12 => 000 1 101
	* 13 => 000 1 110
	* 14 => 000 1 111
	*/
	command uint8_t Codebook8.getCode(uint8_t clear, uint16_t* code) {
		uint8_t depth;
		uint8_t propagate = clear;
		uint8_t prehash = clear ^ (clear>>4);
		/* default if clear is not found in codebook */
		uint8_t length = 8 + 4;
		*code = clear;

		/* search for clear in code book, while at same time inserting clear into codebook */
		for (depth=0; depth<4; depth++) {
			uint8_t offset = (1 << depth) - 1;
			uint8_t hash = (prehash % (offset + 1)) + offset;	
			uint8_t temp = codebook[hash];
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
