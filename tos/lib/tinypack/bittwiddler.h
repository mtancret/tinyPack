#ifndef __BITTWIDDLER_H
#define __BITTWIDDLER_H

/* count leading zeros of a single byte */
inline uint8_t clz8(uint8_t byte) {
	uint8_t count = 0;

	if (byte & 0xf0) {
		byte >>= 4;
	} else {
		count += 4;
	}

	if (byte & 0x0c) {
		byte >>= 2;
	} else {
		count += 2;
	}

	if (!(byte & 0x02)) {
		count++;
	}

	return count;
}

#endif
