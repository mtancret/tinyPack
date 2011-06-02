/**
 * EgaCodebookP.nc
 * (Exponential Golomb Adaptive Codebook)
 * Purpose: Implements an adaptive codebook using exponential
 * golomb coding. Uses 384 bytes of RAM. Also implements a simple
 * compressor using the codebook.
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

#ifndef EXP_GOLOMB_K
/* default exponential golomb model */
#define EXP_GOLOMB_K 2
#endif

generic module EgaCodebookP() {
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
	uint8_t reverse[128];

	command void ChainCompressor.init() {
		uint16_t i;
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
	 * 2^k number of codes can be optimized
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
		/* do not ever need to know the reverse of codes >=128 */
		if (binCode < 128) {
			reverse[binCode] = swapReverse;
		}
		reverse[swapCode] = clear;

		return length;
	}
}
