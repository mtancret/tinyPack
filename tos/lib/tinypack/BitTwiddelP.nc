module BitTwiddelP {
	provides {
		interface BitTwiddler;
	}
}
implementation {
	command uint8_t BitTwiddler.clz8(uint8_t bits) {
		uint8_t bit = 0;

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
}
