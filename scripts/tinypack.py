#!/usr/bin/env python

def getNextByte():
	global inBytes, nextByte
	if nextByte >= len(inBytes):
		b = -1
	else:
		b = int(inBytes[nextByte])
		nextByte += 1
	return b

def readUnsignedInt(bits):
	value=0
	for i in range(0,bits,8):
	 	b = getNextByte()
		value+=(b<<(bits-8-i))
	return value

lzssFrame = []
encByte = 0
encBit = 0
def readBits(numBits):
	global lzssFrame, encByte, encBit

	remainingBits = 8 - encBit

	result = lzssFrame[encByte] >> encBit

	if (numBits == remainingBits):
		encByte += 1
		encBit = 0
	elif (numBits > remainingBits):
		encByte += 1
		result |= lzssFrame[encByte] << remainingBits
		encBit = numBits - remainingBits
	else:
		encBit += numBits

	result &= (0xFF >> (8 - numBits))

	return result

def decode(seq):
	global lzssFrame, encByte, encBit

	lzssFrame = seq
	encByte = 0
	encBit = 0
	decByte = 0
	decoded = []
	while (decByte < 126):
		remaining = 126 - decByte;
		if decByte > 128:
			offsetBits = 8
			lengthBits = 8
		elif decByte > 64:
			offsetBits = 7
			lengthBits = 7
		elif decByte > 32:
			offsetBits = 6
			lengthBits = 6
		elif decByte > 16:
			offsetBits = 5
			lengthBits = 5
		elif decByte > 8:
			offsetBits = 4
			lengthBits = 4
		elif decByte > 4:
			offsetBits = 3
			lengthBits = 3
		elif decByte > 2:
			offsetBits = 2
			lengthBits = 2
		elif decByte > 1:
			offsetBits = 1
			lengthBits = 1
		else:
			offsetBits = 0
			lengthBits = 0
	
		if remaining < 126/2:
			if remaining > 64:
				lengthBits = 7
			elif remaining > 32:
				lengthBits = 6
			elif remaining > 16:
				lengthBits = 5
			elif remaining > 8:
				lengthBits = 4
			elif remaining > 4:
				lengthBits = 3
			elif remaining > 2:
				lengthBits = 2
			elif remaining > 1:
				lengthBits = 1
			else:
				lengthBits = 0

		flag = readBits(1) 
		if flag == 0:
			decoded.append(readBits(8))
			decByte += 1
		else:
			offset = readBits(offsetBits)
			length = readBits(lengthBits)
	
			for i in range(length+1):
				decoded.append(decoded[offset+i])
				decByte += 1
	return decoded

def chainDecode(seq, prev):
	global lzssFrame, encByte, encBit

	lzssFrame = seq
	encByte = 0
	encBit = 0
	decByte = 0
	decoded = []

	offsetBits = 7
	lengthBits = 7
	
	while (decByte < 126):
		remaining = 126 - decByte;

		if remaining < 126/2:
			if remaining > 64:
				lengthBits = 7
			elif remaining > 32:
				lengthBits = 6
			elif remaining > 16:
				lengthBits = 5
			elif remaining > 8:
				lengthBits = 4
			elif remaining > 4:
				lengthBits = 3
			elif remaining > 2:
				lengthBits = 2
			elif remaining > 1:
				lengthBits = 1
			else:
				lengthBits = 0

		flag = readBits(1) 
		if flag == 0:
			decoded.append(readBits(8))
			decByte += 1
		else:
			offset = readBits(offsetBits)
			length = readBits(lengthBits)
	
			for i in range(length+1):
				dicIdx = decByte - 126 + offset + i
				if (dicIdx < 0):
					decoded.append(prev[dicIdx])
				else:
					decoded.append(decoded[dicIdx])

			decByte += length + 1
	return decoded
