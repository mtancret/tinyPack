/**
 * BitPackP.nc
 * Purpose: Implementation of a bit vector utility.
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

module BitPackP {
	provides {
		interface BitPacker;
	}
}
implementation {
	uint8_t* bitVector;
	uint8_t bitVectorMaxLength;
	uint8_t byteIdx;
	int nextBitIdx;

	command void BitPacker.init(uint8_t* vector, uint8_t maxLength) {
		bitVector = vector;
		bitVectorMaxLength = maxLength;	
		byteIdx = 0;
		nextBitIdx = 7;
	}

	/* Appends inVector to the current bit vector.
	 * Bit vectors are filled into bytes from most-significant to
	 * least-significant bit. Bit vectors that streach across a byte
	 * boundery are are ordered big-endian.
	 * Return False if overflow occured.
	 * inVector - right aligned bit vector to append
	 * inVectorLength - length in bits of inVector
	 * returns - FAIL if the bitVector overflows */
	command error_t BitPacker.pack(uint32_t inVector, uint8_t inVectorLength) {
		/* check for overflow */
		if (byteIdx >= bitVectorMaxLength) {
			return FAIL;
		}

		while (inVectorLength > 0) {
			/* how much the current byte has left before it is full */
			uint8_t byteCapacity = nextBitIdx + 1;
			uint8_t writeBits;
			uint8_t mask;
			uint8_t bits;

			if (inVectorLength < byteCapacity) {
				writeBits = inVectorLength;
			} else {
				writeBits = byteCapacity;
			}

			mask = 0xff >> (8 - writeBits);
			bits = inVector >> (inVectorLength - writeBits);
			bitVector[byteIdx] |= (bits & mask) << (byteCapacity - writeBits);

			nextBitIdx -= writeBits;
			inVectorLength -= writeBits;

			if (nextBitIdx == -1) {
				byteIdx++;
				nextBitIdx = 7;
				bitVector[byteIdx] = 0;

				/* check for overflow */
				if (byteIdx >= bitVectorMaxLength) {
					return FAIL;
				}
			}
		}

		return SUCCESS;
	}

	command uint8_t BitPacker.getLength() {
		return nextBitIdx == 0 ? byteIdx : byteIdx + 1;
	}
}
