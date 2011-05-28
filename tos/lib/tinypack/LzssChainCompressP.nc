/**
 * LzssChainCompressP.nc
 * Purpose: Implementation of LZSS-like compression algorithms. Chain
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

generic module LzssChainCompressP() {
	provides {
		interface Init;
		interface ChainCompressor;
	}
	uses {
		interface BitPacker;
	}
}
implementation {
	uint8_t* prev = NULL;
	uint8_t prevLength = 0;

	command error_t Init.init() {
		prev = NULL;
		prevLength = 0;	
		return SUCCESS;
	}

	command uint8_t ChainCompressor.encode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint16_t encStartIdx;
		uint16_t encMatchIdx;
		uint16_t dicStartIdx;
		uint16_t dicMatchIdx;
		uint8_t maxOffset;
		uint8_t maxLength;
		uint8_t offsetBits;
		uint8_t lengthBits;

		offsetBits = 8 - clz8(inLength - 1);
		lengthBits = offsetBits;

		call BitPacker.init(out, outMaxLength);

		/* encode all of in[] */
		encStartIdx = prevLength;
		while (encStartIdx-prevLength < inLength) {


			maxOffset = 0;
			maxLength = 0;
			dicStartIdx = encStartIdx<inLength ? 0 : encStartIdx-inLength;
			/* incrementally search the dictionary until it is no loger possible to find
			   a larger match than maxLength */
			for (; encStartIdx-dicStartIdx > maxLength; dicStartIdx++) {
				uint8_t matchLength;

				encMatchIdx = encStartIdx;
				dicMatchIdx = dicStartIdx;

				while (encMatchIdx-prevLength<inLength
					&& dicMatchIdx<encStartIdx
					&& in[encMatchIdx-prevLength] == (dicMatchIdx<prevLength ? prev[dicMatchIdx] : in[dicMatchIdx-prevLength])) {

					encMatchIdx++;
					dicMatchIdx++;

				}

				matchLength = dicMatchIdx - dicStartIdx;
				if (matchLength > maxLength) {
					maxOffset = dicStartIdx - (encStartIdx - prevLength);
					/* recorded length is one smaller than actual length */
					maxLength = matchLength - 1;
				}
			}

			if (maxLength < 1) {
				if (call BitPacker.pack(0, 1) == FAIL) return 0;
				if (call BitPacker.pack(in[encStartIdx-prevLength], 8) == FAIL) return 0;

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
				if (call BitPacker.pack(maxOffset, offsetBits) == FAIL) return 0;
				if (call BitPacker.pack(maxLength, lengthBits) == FAIL) return 0;

				encStartIdx += maxLength + 1;
			}
		}

		if (prev != NULL) {
			signal ChainCompressor.free(prev);
		}
		prev = in;
		prevLength = inLength;

		return call BitPacker.getLength();
	}

	command uint8_t ChainCompressor.decode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode

		if (prev != NULL) {
			signal ChainCompressor.free(prev);
		}
		prev = out;
		prevLength = outMaxLength;

		return 0;
	}
}
