# Name: tinypack.py
# Purpose: Decompression of tinyPack compressed arrays.
# Author(s): Matthew Tan Creti
# 
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

def clz(value, base):
	mask = pow(2,base) - 1
	zeros = 0
	while mask != 0:
		mask >>= 1
		if (value | mask) != mask:
			return zeros
		zeros += 1

	return zeros

class BitUnpacker(object):
	def __init__(self, bitVector):
		self.bitVector = bitVector
		self.byteIdx = 0
		self.nextBitIdx = 7

	# for small endian byte order
	def getNext(self, numBits):
		result = 0

		while numBits>0:
			remaining = self.nextBitIdx + 1
			if numBits<remaining:
				readBits = numBits
			else:
				readBits = remaining

			mask = 0xff >> (8 - readBits)
			bits = self.bitVector[self.byteIdx] >> (remaining - readBits)
			result |= (bits & mask) << (numBits - readBits)

			self.nextBitIdx -= readBits
			numBits -= readBits

			if self.nextBitIdx == -1:
				self.byteIdx += 1
				self.nextBitIdx = 7

		return result

class BitPacker(object):
	def __init__(self, bitVector=[0], maxLength=None):
		self.bitVector = bitVector
		self.bitVectorMaxLength = maxLength
		self.byteIdx = 0
		self.nextBitIdx = 7

	# Bit vectors are filled into bytes from most-significant to least-significant bit.
	# Bit vectors that streach across a byte boundery are are ordered big-endian.
	# Return False if overflow occured.
	def pack(self, inVector, numBits):
		if self.bitVectorMaxLength != None and self.byteIdx >= self.bitVectorMaxLength:
			return False

		while numBits>0:
			remaining = self.nextBitIdx + 1
			if numBits<remaining:
				writeBits = numBits
			else:
				writeBits = remaining


			mask = 0xff >> (8 - writeBits)
			bits = inVector >> (numBits - writeBits)
			self.bitVector[self.byteIdx] |= (bits & mask) << (remaining - writeBits)

			self.nextBitIdx -= writeBits
			numBits -= writeBits

			if self.nextBitIdx == -1:
				self.bitVector.append(0)
				self.byteIdx += 1
				self.nextBitIdx = 7

				if self.bitVectorMaxLength != None and self.byteIdx >= self.bitVectorMaxLength:
					return False
		return True

	def getBitVector(self):
		return self.bitVector

	def getLength(self):
		if self.nextBitIdx == 0:
			return self.byteIdx
		else:
			return self.byteIdx+1

class ExpGolombCodebook(object):
	def __init__(self, k=2):
		self.k = k
		self.init()

	def init(self):
		self.codebook = range(256)
		self.reverse = range(256)

	def compress(self, text):
		self.init()
		bitPacker = BitPacker()
		for byte in text:
			if self.encodeNext(byte, bitPacker) == False:
				return None

		return bitPacker.getBitVector()

	def expand(self, bitVector, length):
		self.init()
		result = []
		bitUnpacker = BitUnpacker(bitVector)
		for i in range(length):
			result.append(self.decodeNext(bitUnpacker))	
		return result

	def encodeNext(self, clear, bitPacker):
		binCode = self.codebook[clear]

		# convert binCode to an exponential golomb code
		code = binCode + (1 << self.k)
		length = 16 - clz(code, 16)
		length = length + (length - (self.k + 1))

		# some optimization
		#if (binCode >= 252) {
		#	*code = 255 - binCode;
		#	length = 7;
		#}

		self.updateCodebook(binCode)

		bitPacker.pack(code, length)

	def decodeNext(self, bitUnpacker):
		leadingZeros = -1
		nextBit = 0
		while (nextBit == 0):
			leadingZeros += 1
			nextBit = bitUnpacker.getNext(1)

		binCode = bitUnpacker.getNext(
				leadingZeros + self.k
			) + (
				1<<(leadingZeros + self.k)
			) - (
				1 << self.k
			)
		clear = self.reverse[binCode]

		self.updateCodebook(binCode)

		return clear

	def updateCodebook(self, code):
		#swapCode = (code/2 & 0xfc) | ((code + 1) & 0x03)
		swapCode = code/2

		clear = self.reverse[code]
		swapReverse = self.reverse[swapCode]
		self.codebook[clear] = swapCode
		self.codebook[swapReverse] = code
		self.reverse[code] = swapReverse
		self.reverse[swapCode] = clear

class LzssCompressor(object):
	def __init__(self):
		self.previous = None

	def decode(self, seq):
		""" """
		#global lzssFrame, encByte, self.nextBitIdx
	
		#lzssFrame = seq
		#encByte = 0
		#self.nextBitIdx = 0
		#decByte = 0
		#decoded = []
		#while (decByte < 126):
		#	remaining = 126 - decByte

		#	if decByte > 1:
		#		bits = 8 - clz(encStartIdx - 1, 8)
		#		offsetBits = bits
		#		lengthBits = bits
		#	else:
		#		offsetBits = 0
		#		lengthBits = 0

		#	if remaining < 126/2:
		#		if remaining > 1:
		#			bits = 8 - clz(remaining - 1, 8)
		#			lengthBits = bits
		#		 else:
		#			lengthBits = 0

		#	flag = readBits(1) 
		#	if flag == 0:
		#		decoded.append(readBits(8))
		#		decByte += 1
		#	else:
		#		offset = readBits(offsetBits)
		#		length = readBits(lengthBits)
		#
		#		for i in range(length+1):
		#			decoded.append(decoded[offset+i])
		#			decByte += 1
		#return decoded
	
	def chainDecode(seq, prev):
		""" """
		#global lzssFrame, encByte, self.nextBitIdx

		#lzssFrame = seq
		#encByte = 0
		#self.nextBitIdx = 0
		#decByte = 0
		#decoded = []
	
		#offsetBits = 7
		#lengthBits = 7
		#
		#while (decByte < 126):
		#	remaining = 126 - decByte;
	
		#	if remaining < 126/2:
		#		if remaining > 1:
		#			bits = 8 - clz(remaining - 1, 8);
		#			lengthBits = bits;
		#		else:
		#			lengthBits = 0;

		#	flag = readBits(1) 
		#	if flag == 0:
		#		decoded.append(readBits(8))
		#		decByte += 1
		#	else:
		#		offset = readBits(offsetBits)
		#		length = readBits(lengthBits)
		#
		#		for i in range(length+1):
		#			dicIdx = decByte - 126 + offset + i
		#			if (dicIdx < 0):
		#				decoded.append(prev[dicIdx])
		#			else:
		#				decoded.append(decoded[dicIdx])
	
		#		decByte += length + 1
		#return decoded
