/**
 * Name: BitPackP.nc
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
	uint8_t nextBitIdx;

	command void BitPacker.init(uint8_t* vector, uint8_t maxLength) {
		bitVector = vector;
		bitVectorMaxLength = maxLength;	
		byteIdx = 0;
		nextBitIdx = 0;
	}

	/* Appends inVector to the current bit vector.
	   inVector - right aligned bit vector to append
	   inVectorLength - length in bits of inVector, maximum 8
	   returns - FAIL if the bitVector overflows */
	command error_t BitPacker.pack(uint8_t inVector, uint8_t inVectorLength) {
		/* how much the current byte has left before it is full */
		uint8_t byteCapacity = 8-nextBitIdx;

		/* check for overflow */
		if (byteIdx >= bitVectorMaxLength) {
			return FAIL;
		}

		/* if starting a new byte zero it out */
		if (nextBitIdx == 0) {
			bitVector[byteIdx] = 0;
		}

		/* pack inVector into the current byte */
		bitVector[byteIdx] += (inVector << nextBitIdx);

		/* check if the byte is now full */
		if (byteCapacity == inVectorLength) {
			byteIdx++;
			nextBitIdx = 0;
		/* check if not all of inVector fits into the byte */
		} else if (byteCapacity < inVectorLength) {
			byteIdx++;

			/* check for overflow */
			if (byteIdx >= bitVectorMaxLength) {
				return FAIL;
			}

			/* pack the remaining bits */
			bitVector[byteIdx] = inVector >> byteCapacity;
			nextBitIdx = inVectorLength - byteCapacity;
		} else {
			nextBitIdx += inVectorLength;
		}

		return SUCCESS;
	}

	command uint8_t BitPacker.getLength() {
		return nextBitIdx == 0 ? byteIdx : byteIdx + 1;
	}
}
