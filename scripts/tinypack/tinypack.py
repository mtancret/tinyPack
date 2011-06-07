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

DEBUG = True

# Counts the leading zeros of a value stored in big-endian binary frame.
# For example, clz(0x0f, 8) returns 4.
# value - the value stored in the binary frame
# size - the number of bits in the binary frame
# returns the number of leading zeros
def clz(value, size):
	mask = pow(2,size) - 1
	zeros = 0
	while mask != 0:
		mask >>= 1
		if (value | mask) != mask:
			return zeros
		zeros += 1

	return zeros

# Iterates through a bit vector a variable number of bits at a time.
# A bit vector is stored as a list of numbers (each of byte size).
# Numbers are packed into the bit vector big-endian.
class BitUnpacker(object):

	# bitVector - the bits vector to unpack
	def __init__(self, bitVector):
		self.bitVector = bitVector
		self.byteIdx = 0
		self.nextBitIdx = 7

	# Reads the next number of bits from the bit vector.
	# numBits - number of bits to read
	# returns a number
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

# Iteratively builds a bit vector a variable number of bits at a time.
# A bit vector is stored as a list of numbers (each of byte size).
# Numbers are packed into the bit vector bit-endian first.
class BitPacker(object):

	# bitVector - list of bytes, default [0]
	# maxLength - limit of how large bitVector can grow, default None
	def __init__(self, bitVector=None, maxLength=None):
		if bitVector == None:
			self.bitVector = [0]
		else:
			self.bitVector = bitVector
		self.bitVectorMaxLength = maxLength
		self.byteIdx = 0
		self.nextBitIdx = 7

	# Packs inVector into the bit vector.
	# inVector - an unsigned number
	# numBits - size of inVector in bits
	# returns False if overflow occured
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
		if self.nextBitIdx == 7:
			return self.bitVector[:-1]
		else:
			return self.bitVector

	# returns length of bit vector in bytes
	def getLength(self):
		if self.nextBitIdx == 7:
			return self.byteIdx
		else:
			return self.byteIdx+1

class NoCodebook(object):
	def init(self):
		""" """

	def encodeNext(self, clear, bitPacker):
		if DEBUG: print "Encoding literal: clear=",clear,"code=",clear,"bits= 8"
		bitPacker.pack(clear, 8)

	def decodeNext(self, bitUnpacker):
		clear = bitUnpacker.getNext(8)
		if DEBUG: print "Decoded literal: code=",clear,"clear=",clear
		return clear

class EgaCodebook(object):
	def __init__(self, k=2):
		self.k = k
		self.init()

	def init(self):
		self.codebook = range(256)
		self.reverse = range(256)

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

		if DEBUG: print "Encoding literal: clear=",clear,"code=",code,"bits=",length

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

		if DEBUG: print "Decoded literal: clear=",clear

		return clear

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

	def updateCodebook(self, code):
		#swapCode = (code/2 & 0xfc) | ((code + 1) & 0x03)
		swapCode = code/2

		clear = self.reverse[code]
		swapReverse = self.reverse[swapCode]
		self.codebook[clear] = swapCode
		self.codebook[swapReverse] = code
		self.reverse[code] = swapReverse
		self.reverse[swapCode] = clear

class Lzrw(object):
	def __init__(self, blockSize, codebook=None, lzrwTableSize=128):
		self.blockSize = blockSize
		if codebook == None:
			self.codebook = NoCodebook()
		else:
			self.codebook = codebook
		self.lzrwTableSize = lzrwTableSize
		self.init()

	def init(self):
		self.codebook.init()
		self.lzss = Lzss(self.blockSize, self.codebook)

		self.prev = None
		self.prevLength = 0
		self.prevPrevLength = 0
		self.table = [0] * self.lzrwTableSize

	def expand(self, seq):
		return self.lzss.expand(seq)

	def chainExpand(self, seq):
		return self.lzss.chainExpand(seq)

	def chainCompress(self, seq):
		if DEBUG: print "LZRW chain compressing:",seq

		bitPacker = BitPacker()
		dicStartidx = 0

		offsetBits = 16 - clz(self.prevLength + len(seq) - 1, 16)
		lengthBits = offsetBits

		# update hash table references
		for i in range(self.lzrwTableSize):
			self.table[i] = (self.table[i] - self.prevPrevLength) % 256

		# encode all of seq[]
		encStartIdx = self.prevLength
		while encStartIdx - self.prevLength < len(seq):
			encStartIn = encStartIdx - self.prevLength
			length = 0
			if len(seq) - encStartIn > 2:
				hash = (seq[encStartIn] + (seq[encStartIn] << 4) + seq[encStartIn+1] + seq[encStartIn+2]) % self.lzrwTableSize
				dicStartIdx = self.table[hash];
				encMatchIdx = encStartIdx;
				dicMatchIdx = dicStartIdx;

				while (encMatchIdx - self.prevLength < len(seq)
					and dicMatchIdx < encStartIdx
					and (
						(
							dicMatchIdx < self.prevLength
							and
							seq[encMatchIdx-self.prevLength] == self.prev[dicMatchIdx]
						) or (
							dicMatchIdx >= self.prevLength
							and
							seq[encMatchIdx-self.prevLength] == seq[dicMatchIdx - self.prevLength]
						)
					)):
					encMatchIdx+=1
					dicMatchIdx+=1

				if dicMatchIdx != encStartIdx:
					self.table[hash] = encStartIdx

				length = dicMatchIdx - dicStartIdx

			if length < 3:
				bitPacker.pack(0, 1)
				self.codebook.encodeNext(seq[encStartIdx-self.prevLength], bitPacker)

				encStartIdx+=1
			else:
				remaining = len(seq) - (encStartIdx - self.prevLength)

				if remaining < len(seq)/2:
					if remaining > 1:
						bits = 8 - clz(remaining - 1, 8)
						lengthBits = bits
					else:
						lengthBits = 0

				if DEBUG: print "Encoding reference: offset=",dicStartIdx,"length=",length-1

				bitPacker.pack(1, 1)
				bitPacker.pack(dicStartIdx, offsetBits)
				# recorded length is one smaller than actual length
				bitPacker.pack(length - 1, lengthBits)

				encStartIdx += length

		self.prev = seq
		self.prevPrevLength = self.prevLength
		self.prevLength = len(seq)

		if DEBUG: print "Compressed bit vector:",bitPacker.getBitVector(),"\n"

		return bitPacker.getBitVector()

class Lzss(object):
	def __init__(self, blockSize, codebook=None):
		self.blockSize = blockSize
		if codebook == None:
			self.codebook = NoCodebook()
		else:
			self.codebook = codebook
		self.init()

	def init(self):
		self.prev = None
		self.prevLength = 0

	def expand(self, seq):
		self.init()
		bitUnpacker = BitUnpacker(seq)
		decByte = 0
		decoded = []
		while (decByte < self.blockSize):
			remaining = self.blockSize - decByte

			if decByte > 1:
				bits = 8 - clz(encStartIdx - 1, 8)
				offsetBits = bits
				lengthBits = bits
			else:
				offsetBits = 0
				lengthBits = 0

			if remaining < self.blockSize/2:
				if remaining > 1:
					bits = 8 - clz(remaining - 1, 8)
					lengthBits = bits
				else:
					lengthBits = 0

			flag = bitUnpacker.getNext(1)
			if flag == 0:
				byte = codebook.decodeNext(bitUnpacker)
				decoded.append(byte)
				decByte += 1
			else:
				offset = bitUnpacker.getNext(offsetBits)
				length = bitUnpacker.getNext(lengthBits)

				for i in range(length+1):
					decoded.append(decoded[offset+i])
					decByte += 1
		return decoded
	
	def chainExpand(self, seq):
		if DEBUG: print "LZSS chain expanding:",seq

		bitUnpacker = BitUnpacker(seq)
		decByte = 0
		decoded = []

		offsetBits = 16 - clz(self.prevLength + self.blockSize - 1, 16)
		lengthBits = offsetBits

		while (decByte < self.blockSize):
			remaining = self.blockSize - decByte

			if remaining < self.blockSize/2:
				if remaining > 1:
					bits = 8 - clz(remaining - 1, 8)
					lengthBits = bits
				else:
					lengthBits = 0

			flag = bitUnpacker.getNext(1) 
			if flag == 0:
				byte = self.codebook.decodeNext(bitUnpacker)
				decoded.append(byte)

				decByte += 1
			else:
				offset = bitUnpacker.getNext(offsetBits)
				length = bitUnpacker.getNext(lengthBits)

				for i in range(length+1):
					dicIdx = offset + i
					if (dicIdx < self.prevLength):
						decoded.append(self.prev[dicIdx])
					else:
						decoded.append(decoded[dicIdx - self.prevLength])

				if DEBUG: print "Decoded reference: offset=",offset,"length=",length,decoded[-length-1:]

				decByte += length + 1

		self.prev = decoded
		self.prevLength = self.blockSize

		if DEBUG: print "LZSS expanded:",seq,"\n"

		return decoded
