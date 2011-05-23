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

#include "bittwiddel.h"

module LzssChainCompressP {
	provides {
		interface ChainCompressor;
	}
	uses {
		interface BitPacker;
	}
}
implementation {
	command uint8_t ChainCompressor.chainEncode(uint8_t* prev, uint8_t* in, uint8_t* out, uint8_t prevLength, uint8_t inLength, uint8_t outMaxLength) {
		uint16_t encStartIdx;
		uint16_t encMatchIdx;
		uint16_t dicStartIdx;
		uint16_t dicMatchIdx;
		uint8_t maxOffset;
		uint8_t maxLength;
		uint8_t offsetBits;
		uint8_t lengthBits;

		if (prevLength > 1) {
			uint8_t bits = 8 - clz8(prevLength - 1);
			offsetBits = bits;
			lengthBits = bits;
		} else {
			offsetBits = 0;
			lengthBits = 0;
		}

		call BitPacker.init(out, outMaxLength);

		/* encode all of in[] */
		encStartIdx = prevLength;
		while (encStartIdx-prevLength < inLength) {


			maxOffset = 0;
			maxLength = 0;
			/* incrementally search the dictionary until it is no loger possible to find
			   a larger match than maxLength */
			for (dicStartIdx = encStartIdx-prevLength; encStartIdx-dicStartIdx > maxLength; dicStartIdx++) {
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

		return call BitPacker.getLength();
	}

	command uint8_t ChainCompressor.chainDecode(uint8_t* prev, uint8_t* in, uint8_t* out, uint8_t prevLength, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode
		return 0;
	}
}
