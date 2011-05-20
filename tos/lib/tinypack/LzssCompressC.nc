# Copyright 2011 Matthew Tan Creti
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module LzssCompressC {
	provides {
		interface Compressor;
	}
}
implementation {
	uint8_t* bitfield;
	uint8_t bitfieldMaxLength;
	uint8_t byteIdx;
	uint8_t nextBitIdx;

	/* Assumes bits are aligned to least significant digits and masked. Also, numBits <= 8. */
	error_t pack(uint8_t bits, uint8_t numBits) {
		/* how much the current byte has left before it is full */
		uint8_t byteCapacity = 8-nextBitIdx;

		/* check for overflow */
		if (byteIdx >= bitfieldMaxLength) {
			return FAIL;
		}

		/* if starting a new byte zero it out */
		if (nextBitIdx == 0) {
			bitfield[byteIdx] = 0;
		}

		/* pack bits into the current byte */
		bitfield[byteIdx] += (bits << nextBitIdx);

		/* check if the byte is now full */
		if (byteCapacity == numBits) {
			byteIdx++;
			nextBitIdx = 0;
		/* check if not all of the bits fit into the byte */
		} else if (byteCapacity < numBits) {
			byteIdx++;

			/* check for overflow */
			if (byteIdx >= bitfieldMaxLength) {
				return FAIL;
			}

			/* pack the remaining bits */
			bitfield[byteIdx] = bits >> byteCapacity;
			nextBitIdx = numBits - byteCapacity;
		} else {
			nextBitIdx += numBits;
		}

		return SUCCESS;
	}

	command uint8_t Compressor.compress(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength) {
		uint8_t encStartIdx;
		uint8_t encMatchIdx;
		uint8_t dicStartIdx;
		uint8_t dicMatchIdx;
		uint8_t maxOffset;
		uint8_t maxLength;

		bitfield = out;
		bitfieldMaxLength = outMaxLength;
		byteIdx = 0;
		nextBitIdx = 0;

		encStartIdx = 0;
		while (encStartIdx<inLength) {
			maxOffset = 0;
			maxLength = 0;
			encMatchIdx = encStartIdx;
			dicStartIdx = 0;
			dicMatchIdx = dicStartIdx;

			while (encStartIdx-dicStartIdx > maxLength) {

				while (encMatchIdx<inLength && dicMatchIdx<encStartIdx && in[encMatchIdx] == in[dicMatchIdx]) {
					/* length is one smaller than actual length */
					uint8_t thisLength = dicMatchIdx - dicStartIdx;
					if (thisLength > maxLength) {
						maxOffset = dicStartIdx;
						maxLength = thisLength;
					}

					encMatchIdx++;
					dicMatchIdx++;
				}

				encMatchIdx = encStartIdx;
				dicStartIdx++;
				dicMatchIdx = dicStartIdx;
			}

			if (maxLength < 1) {
				if (pack(0, 1) == FAIL) return 0;
				if (pack(in[encStartIdx], 8) == FAIL) return 0;

				encStartIdx++;
			} else {
				uint8_t offsetBits;
				uint8_t lengthBits;
				uint8_t remaining = inLength - encStartIdx;

				if (encStartIdx > 128) {
					offsetBits = 8;
					lengthBits = 8;
				} else if (encStartIdx > 64) {
					offsetBits = 7;
					lengthBits = 7;
				} else if (encStartIdx > 32) {
					offsetBits = 6;
					lengthBits = 6;
				} else if (encStartIdx > 16) {
					offsetBits = 5;
					lengthBits = 5;
				} else if (encStartIdx > 8) {
					offsetBits = 4;
					lengthBits = 4;
				} else if (encStartIdx > 4) {
					offsetBits = 3;
					lengthBits = 3;
				} else if (encStartIdx > 2) {
					offsetBits = 2;
					lengthBits = 2;
				} else if (encStartIdx > 1) {
					offsetBits = 1;
					lengthBits = 1;
				} else {
					offsetBits = 0;
					lengthBits = 0;
				}

				if (remaining < inLength/2) {
					if (remaining > 64) {
						lengthBits = 7;
					} else if (remaining > 32) {
						lengthBits = 6;
					} else if (remaining > 16) {
						lengthBits = 5;
					} else if (remaining > 8) {
						lengthBits = 4;
					} else if (remaining > 4) {
						lengthBits = 3;
					} else if (remaining > 2) {
						lengthBits = 2;
					} else if (remaining > 1) {
						lengthBits = 1;
					} else {
						lengthBits = 0;
					}
				}

				if (pack(1, 1) == FAIL) return 0;
				if (pack(maxOffset, offsetBits) == FAIL) return 0;
				if (pack(maxLength, lengthBits) == FAIL) return 0;

				encStartIdx += maxLength + 1;
			}
		}

		if (nextBitIdx != 0) {
			byteIdx++;
		}

		return byteIdx;
	}

	command uint8_t Compressor.chainCompress(uint8_t* prev, uint8_t* in, uint8_t* out, uint8_t prevLength, uint8_t inLength, uint8_t outMaxLength) {
		uint16_t encStartIdx;
		uint16_t encMatchIdx;
		uint16_t dicStartIdx;
		uint16_t dicMatchIdx;
		uint8_t maxOffset;
		uint8_t maxLength;
		uint8_t offsetBits;
		uint8_t lengthBits;

		if (prevLength > 128) {
			offsetBits = 8;
			lengthBits = 8;
		} else if (prevLength > 64) {
			offsetBits = 7;
			lengthBits = 7;
		} else if (prevLength > 32) {
			offsetBits = 6;
			lengthBits = 6;
		} else if (prevLength > 16) {
			offsetBits = 5;
			lengthBits = 5;
		} else if (prevLength > 8) {
			offsetBits = 4;
			lengthBits = 4;
		} else if (prevLength > 4) {
			offsetBits = 3;
			lengthBits = 3;
		} else if (prevLength > 2) {
			offsetBits = 2;
			lengthBits = 2;
		} else if (prevLength > 1) {
			offsetBits = 1;
			lengthBits = 1;
		} else {
			offsetBits = 0;
			lengthBits = 0;
		}

		bitfield = out;
		bitfieldMaxLength = outMaxLength;
		byteIdx = 0;
		nextBitIdx = 0;

		encStartIdx = prevLength;
		while (encStartIdx-prevLength < inLength) {
			maxOffset = 0;
			maxLength = 0;
			encMatchIdx = encStartIdx;
			dicStartIdx = encStartIdx - prevLength;
			dicMatchIdx = dicStartIdx;

			while (encStartIdx-dicStartIdx > maxLength) {

				while (encMatchIdx-prevLength<inLength
					&& dicMatchIdx<encStartIdx
					&& in[encMatchIdx-prevLength] == (dicMatchIdx<prevLength ? prev[dicMatchIdx] : in[dicMatchIdx-prevLength])) {
					/* length is one smaller than actual length */
					uint8_t thisLength = dicMatchIdx - dicStartIdx;
					if (thisLength > maxLength) {
						maxOffset = dicStartIdx - (encStartIdx - prevLength);
						maxLength = thisLength;
					}

					encMatchIdx++;
					dicMatchIdx++;
				}

				encMatchIdx = encStartIdx;
				dicStartIdx++;
				dicMatchIdx = dicStartIdx;
			}

			if (maxLength < 1) {
				if (pack(0, 1) == FAIL) return 0;
				if (pack(in[encStartIdx-prevLength], 8) == FAIL) return 0;

				encStartIdx++;
			} else {
				uint8_t remaining = inLength - (encStartIdx - prevLength);

				if (remaining < inLength/2) {
					if (remaining > 64) {
						lengthBits = 7;
					} else if (remaining > 32) {
						lengthBits = 6;
					} else if (remaining > 16) {
						lengthBits = 5;
					} else if (remaining > 8) {
						lengthBits = 4;
					} else if (remaining > 4) {
						lengthBits = 3;
					} else if (remaining > 2) {
						lengthBits = 2;
					} else if (remaining > 1) {
						lengthBits = 1;
					} else {
						lengthBits = 0;
					}
				}

				if (pack(1, 1) == FAIL) return 0;
				if (pack(maxOffset, offsetBits) == FAIL) return 0;
				if (pack(maxLength, lengthBits) == FAIL) return 0;

				encStartIdx += maxLength + 1;
			}
		}

		if (nextBitIdx != 0) {
			byteIdx++;
		}

		return byteIdx;
	}
}
