#include "bittwiddel.h"

char clz8(char bits) {
	char bit = 0;

	if (bits & 0xf0) {
		bits >>= 4;
	} else {
		bit += 4;
	}

	if (bits & 0x0c) {
		bits >>= 2;
	} else {
		bit += 2;
	}

	if (!(bits & 0x02)) {
		bit++;
	}

	return bit;
}
