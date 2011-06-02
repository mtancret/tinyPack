/**
 * EgaCodebookC.nc
 * (Exponential Golomb Adaptive Codebook)
 * Purpose: An adaptive codebook using exponential golomb coding.
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

generic configuration EgaCodebookC() {
	provides {
		interface Codebook;
		interface ChainCompressor;
	}
}
implementation {
	components new EgaCodebookP() as EgaCodebookP;
	components BitPackP;

	Codebook = EgaCodebookP.Codebook;
	ChainCompressor = EgaCodebookP.ChainCompressor;
	EgaCodebookP.BitPacker -> BitPackP.BitPacker;
}
