/**
 * LzrwEgaChainC.nc
 * Purpose: Implementation of LZRW-like compression algorithms. Chain
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

generic configuration LzrwEgaChainC() {
	provides {
		interface ChainCompressor;
	}
}
implementation {
	components new LzrwChainP() as LzrwChain;
	components new EgaCodebookC() as Codebook;
	components BitPackP;

	ChainCompressor = LzrwChain.ChainCompressor;
	LzrwChain.Codebook -> Codebook.Codebook;
	LzrwChain.BitPacker -> BitPackP.BitPacker;
}
