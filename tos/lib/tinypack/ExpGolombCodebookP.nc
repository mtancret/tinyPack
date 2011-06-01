/**
 * ExpGolombCodebookP.nc
 * Purpose: An adaptive codebook using an exponential golomb code.
 * Requires 512 bytes of RAM.
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

#define EXP_GOLOMB_K 2

generic module ExpGolombCodebookP() {
	provides {
		interface Codebook;
		interface ChainCompressor;
	}
	uses {
		interface BitPacker;
	}
}
implementation {
	uint8_t codebook[256];
	uint8_t reverse[256];

	command void ChainCompressor.init() {
		uint8_t i;
		for (i=0; i<256; i++) {
			codebook[i] = i;
			reverse[i] = i;	
		}
	}

	command uint8_t ChainCompressor.encode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint8_t i;

		call BitPacker.init(out, outMaxLength);
		for (i=0; i<inLength; i++) {
			uint16_t code;
			uint8_t length = call Codebook.getCode(in[i], &code);
			if (call BitPacker.pack(code, length) == FAIL) return 0;
		}

		return call BitPacker.getLength();
	}

	command uint8_t ChainCompressor.decode(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		// TODO: implement decode
		return 0;
	}

	/**
	 * For EXP_GOLOMB_K = 2
	 * binCode => code
	 *   0 => 1 00 
	 *   1 => 1 01
	 *   2 => 1 10
	 *   3 => 1 11
	 * 
	 *   4 => 0 1 000
	 *   5 => 0 1 001
	 *   6 => 0 1 010
	 *   7 => 0 1 011
	 *   8 => 0 1 100
	 *   9 => 0 1 101
	 *  10 => 0 1 110
	 *  11 => 0 1 111
	 *
	 * ...
	 *
	 * 252 => 00000 00
	 * ...
	 * 255 => 00000 11
	 */
	command uint8_t Codebook.getCode(uint8_t clear, uint16_t* code) {
		/* the length of the returned code in bits */
		uint8_t length;
		/* the code in binary */
		uint8_t binCode = codebook[clear];
		uint8_t swapCode;
		uint8_t swapReverse;

		/* convert binCode to an exponential golomb code */
		*code = binCode + (1 << EXP_GOLOMB_K);
		length = 8*sizeof(*code) - clz(*code);
		length = length + (length - (EXP_GOLOMB_K + 1));

		/* some optimization */
		//if (binCode >= 252) {
		//	*code = 255 - binCode;
		//	length = 7;
		//}

		/* swap binCode with binCode/2 */
		swapCode = binCode/2;
		swapReverse = reverse[swapCode];
		codebook[clear] = swapCode;
		codebook[swapReverse] = binCode;
		reverse[binCode] = swapReverse;
		reverse[swapCode] = clear;

		return length;
	}
}

//		uint8_t depth;
//		uint8_t prehash = clear ^ (clear >> 4);
//		uint8_t lastIdx;
//
//		/* default if clear is not found in codebook */
//		uint8_t length = 9;
//		*code = clear + 0x0100;
//
//		/* search for clear in code book */
//		for (depth=0; depth<3; depth++) {
//			uint8_t offset = (1 << (2 + depth)) - 4;
//			uint8_t hash = (prehash % (offset + 4)) + offset;	
//			if (codebook[hash] == clear) {
//				if (dpeth == 2) {
//					/* terminal depth has prefix of just 000 */
//					*code = hash - offset;
//					length = 7;
//				} else {
//					*code = hash - offset + (4 << depth);
//					length = 2*depth + 4;
//				}
//
//				/* push clear to a higher level */
//				codebook[hash] = codebook[lastIdx];
//				codebook[lastIdx] = clear;
//
//				break;
//			}
//			codebook[hash] = propagate;	
//			propagate = temp;
//		}
//
//		return length;
