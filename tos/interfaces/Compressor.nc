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

interface Compressor {
	/* in - location of uncompressed text
	   out - where compressed text will be written
	   inLength - length of uncompressed text
	   outMaxLength - maximum allowable compressed text length
	   return - length of compressed text, or 0 if compression failed */
	command uint8_t compress(uint8_t* in, uint8_t* out, uint8_t inLength, uint8_t outMaxLength);

	/* prev - the location of the previous text in the chain
	   in - location of uncompressed text
	   out - where compressed text will be written
	   prevLength - length of the previous text
	   inLength - length of uncompressed text
	   outMaxLength - maximum allowable compressed text length
	   return - length of compressed text, or 0 if compression failed */
	command uint8_t chainCompress(uint8_t* prev, uint8_t* in, uint8_t* out, uint8_t prevLength, uint8_t inLength, uint8_t outMaxLength);
}
