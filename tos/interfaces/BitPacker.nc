/**
 * BitPacker.nc
 * Purpose: Interface for a bit vector utility.
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

interface BitPacker {
	/* Initialize the BitPacker.
	   bitVector - where the bit vector will be stored
	   maxLength - maximum bitVector length in bytes */
	command void init(uint8_t* bitVector, uint8_t maxLength);

	/* Appends inVector to the current bit vector.
	   inVector - right aligned bit vector to append
	   inVectorLength - length in bits of inVector
	   returns - FAIL if the bitVector overflows */
	command error_t pack(uint32_t inVector, uint8_t inVectorLength);

	command uint8_t getLength();
}
