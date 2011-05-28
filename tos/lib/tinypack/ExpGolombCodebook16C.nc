/**
 * ExpGolombCodebook16C.nc
 * Purpose: An adaptive codebook based on a hash table and the exponential
 * golomb code. Uses 512 bytes of RAM.
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

generic configuration ExpGolombCodebook16C() {
	provides {
		interface Codebook16;
		interface ChainCompressor;
	}
}
implementation {
	components new ExpGolombCodebook16P() as ExpGolombCodebook16P;
	components BitPackP;

	Codebook16 = ExpGolombCodebook16P.Codebook16;
	ChainCompressor = ExpGolombCodebook16P.ChainCompressor;
	ExpGolombCodebook16P.BitPacker -> BitPackP.BitPacker;
}
