/*
20080912
D. J. Bernstein
Public domain.
*/

#include "poly1305.h"
#include <stdint.h>

typedef uint32_t uint32;
typedef uint64_t uint64;
typedef uint_fast8_t ctr;
typedef const uint32 rad32[5];
typedef const uint32 rad26[5];
typedef uint32 mut32[5];
typedef uint32 mut26[5];

extern void mulmod26(uint32 h[5], const uint32 r[5]);
extern void reduce26(uint32 h[5]);
extern void add26(uint32 h[5], uint32 c[5]);

// little-endian bytewise addition on 136 bits
static void add(unsigned int h[17], const unsigned int c[17]) {
    // loop counter
    unsigned int j;

    // buffer for local result (8 bits) and carry (1 bit). 32 bits.
    unsigned int u = 0;

    for (j = 0; j < 17; ++j) {
        u += h[j] + c[j];
        h[j] = u & 255;
        u >>= 8;
    }
}

// Resolve carries until every array element except the most significant one
// fits in a single byte.
static void squeeze(unsigned int h[17]) {
    // loop counter
    unsigned int j;

    // result buffer
    unsigned int u = 0;

    // Carry loop on first 128 bits.
    for (j = 0; j < 16; ++j) {
        u += h[j];
        h[j] = u & 255;
        u >>= 8;
    }

    // Add with carry on last 2 bits. Keep overflow in u.
    u += h[16];
    h[16] = u & 3;

    // For every 2**130 we cut off, add 5 back to stay equal mod 2**130-5 .
    u = 5 * (u >> 2);

    // Carry on first 128 bits.
    for (j = 0; j < 16; ++j) {
        u += h[j];
        h[j] = u & 255;
        u >>= 8;
    }

    // leave final carry in top byte. Note: this is reduced, but not uniquely
    // so in mod 2**130-5: 2**130-1 written as
    // 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff
    // 0xff 0x3 would remain that way, while in mod 2**130-5 it equals 4
    u += h[16];
    h[16] = u;
}

// that is, -p, little-endian, 2's complement in 136 bits, 8-bit radix
static const unsigned int minusp[17] = {5, 0, 0, 0, 0, 0, 0, 0,  0,
                                        0, 0, 0, 0, 0, 0, 0, 252};

// Reduce modulo p a number 0 <= h < 2p, that is:
// if (h >= p) { h -= p; }
static void freeze(unsigned int h[17]) {
    unsigned int horig[17];
    unsigned int j;
    unsigned int negative;

    for (j = 0; j < 17; ++j) {
        horig[j] = h[j];
    }

    add(h, minusp);
    negative = -(h[16] >> 7);

    for (j = 0; j < 17; ++j) {
        h[j] ^= negative & (horig[j] ^ h[j]);
    }
}

static void mulmod(unsigned int h[17], const unsigned int r[17]) {
    unsigned int hr[17];
    unsigned int i;
    unsigned int j;
    unsigned int u;

    for (i = 0; i < 17; ++i) {
        u = 0;
        for (j = 0; j <= i; ++j) {
            u += h[j] * r[i - j];
        }

        // modular wraparound. 320 = 5 * 64 . 5 is for 2**130-5, but what is 64?
        // Answer: 2**(8-(130-128)). This is the "gap" Bernstein talks about.
        for (j = i + 1; j < 17; ++j) {
            u += 320 * h[j] * r[i + 17 - j];
        }

        hr[i] = u;
    }

    for (i = 0; i < 17; ++i) {
        h[i] = hr[i];
    }

    squeeze(h);
}
