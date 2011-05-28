/**
 * ExpGolombCodebook8C.nc
 * Purpose: An adaptive codebook based on a hash table and the exponential
 * golomb code. Uses 15 bytes of RAM.
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

generic configuration ExpGolombCodebook8C() {
	provides {
		interface Codebook8;
		interface ChainCompressor;
	}
}
implementation {
	components new ExpGolombCodebook8P() as ExpGolombCodebook8P;
	components BitPackP;

	Codebook8 = ExpGolombCodebook8P.Codebook8;
	ChainCompressor = ExpGolombCodebook8P.ChainCompressor;
	ExpGolombCodebook8P.BitPacker -> BitPackP.BitPacker;
}
