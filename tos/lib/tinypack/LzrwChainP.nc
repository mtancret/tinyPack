/**
 * LzrwChainP.nc
 * Purpose: Implementation of LZRW-like compression algorithms. Chain
 * compression can increase compression efficiency by using the previously
 * compressed text as a dictionary for compressing the current text.
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

#include "bittwiddler.h"

#ifndef LZRW_TABLE_SIZE
/* default hash table size, maximum 256 */
#define LZRW_TABLE_SIZE 128
#endif

generic module LzrwChainP() {
	provides {
		interface Init;
		interface ChainCompressor;
	}
	uses {
		interface BitPacker;
		interface Codebook;
	}
}
implementation {
	uint8_t* prev = NULL;
	uint8_t prevLength = 0;
	uint8_t prevPrevLength = 0;
	uint8_t table[LZRW_TABLE_SIZE];

	command error_t Init.init() {
		call ChainCompressor.init();
		return SUCCESS;
	}

	command void ChainCompressor.init() {
		prev = NULL;
		prevLength = 0;	
	}

	command uint8_t ChainCompressor.compress(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint16_t i;
		uint16_t encStartIdx;
		uint16_t encMatchIdx;
		uint16_t dicStartIdx = 0;
		uint16_t dicMatchIdx;
		uint8_t length;
		uint8_t offsetBits;
		uint8_t lengthBits;
		uint8_t hash;

		offsetBits = 16 - clz((uint16_t)prevLength + inLength - 1);
		lengthBits = offsetBits;

		call BitPacker.init(out, outMaxLength);

		/* update hash table references */
		for (i=0; i<LZRW_TABLE_SIZE; i++) {
			table[i] -= prevPrevLength;
		}

		/* encode all of in[] */
		encStartIdx = prevLength;
		while (encStartIdx-prevLength < inLength) {
			uint16_t encStartIn = encStartIdx - prevLength;
			length = 0;
			if (inLength - encStartIn > 2) {
				hash = (in[encStartIn] + (in[encStartIn] << 4) + in[encStartIn+1] + in[encStartIn+2]) % LZRW_TABLE_SIZE;
				dicStartIdx = table[hash];
				encMatchIdx = encStartIdx;
				dicMatchIdx = dicStartIdx;

				while (encMatchIdx - prevLength < inLength
					&& dicMatchIdx < encStartIdx
					&& in[encMatchIdx-prevLength] == (dicMatchIdx<prevLength ? prev[dicMatchIdx] : in[dicMatchIdx-prevLength])) {
					encMatchIdx++;
					dicMatchIdx++;
				}

				if (dicMatchIdx != encStartIdx) {
					table[hash] = encStartIdx;
				}

				length = dicMatchIdx - dicStartIdx;
			}

			if (length < 3) {
				uint16_t code;
				uint8_t codeLength;

				codeLength = call Codebook.encode(in[encStartIdx-prevLength], &code);
				if (call BitPacker.pack(0, 1) == FAIL) return 0;
				if (call BitPacker.pack(code, codeLength) == FAIL) return 0;

				encStartIdx++;
			} else {
				uint8_t remaining = inLength - (encStartIdx - prevLength);

				if (remaining < inLength/2) {
					if (remaining > 1) {
						uint8_t bits = 8 - clz8(remaining - 1);
						lengthBits = bits;
					} else {
						lengthBits = 0;
					}
				}

				if (call BitPacker.pack(1, 1) == FAIL) return 0;
				if (call BitPacker.pack(dicStartIdx, offsetBits) == FAIL) return 0;
				/* recorded length is one smaller than actual length */
				if (call BitPacker.pack(length - 1, lengthBits) == FAIL) return 0;

				encStartIdx += length;
			}
		}

		if (prev != NULL) {
			signal ChainCompressor.free(prev);
		}
		prev = in;
		prevPrevLength = prevLength;
		prevLength = inLength;

		return call BitPacker.getLength();
	}

	command uint8_t ChainCompressor.expand(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode

		if (prev != NULL) {
			signal ChainCompressor.free(prev);
		}
		prev = out;
		prevLength = outMaxLength;

		return 0;
	}
}
