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

static void add32(uint32 h[5], const uint32 c[5]) {
    uint64 u = 0;

    for (ctr j = 0; j < 5; ++j) {
        u += h[j] + c[j];
        h[j] = (uint32)u;
        u >>= 32;
    }
}

static void add26(uint32 h[5], const uint32 c[5]) {
    uint32 u = 0;

    for (ctr j = 0; j < 5; ++j) {
        u += h[j] + c[j];
        h[j] = u & 0x03ffffff;
        u >>= 26;
    }
}

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

static void squeeze32(mut32 h) {
    ctr j = 0;
    uint64 u = 0;

    // Skip carry loop: there is no slack

    u += h[4];
    h[4] = ((uint32)u) & 0x3;
    u = 5 * (u >> 2);

    for (j = 0; j < 4; ++j) {
        u += h[j];
        h[j] = (uint32)u;
        u >>= 32;
    }

    u += h[4];
    h[4] = (uint32)u;
}

static void squeeze26(mut26 h) {
    ctr j = 0;
    uint32 u = 0;

    for (j = 0; j < 4; ++j) {
        u += h[j];
        h[j] = u & 0x03ffffff;
        u >>= 26;
    }

    u += h[4];
    h[4] = u & 0x03ffffff;
    u = 5 * (u >> 26);

    for (j = 0; j < 4; ++j) {
        u += h[j];
        h[j] = u & 0x03ffffff;
        u >>= 26;
    }

    u += h[4];
    h[4] = u;
}

// that is, -p, little-endian, 2's complement in 136 bits, 8-bit radix
static const unsigned int minusp[17] = {5, 0, 0, 0, 0, 0, 0, 0,  0,
                                        0, 0, 0, 0, 0, 0, 0, 252};

// 2's complement in 160 bits, 32-bit radix
static rad32 minp32 = {5, 0, 0, 0, 0xfffffffc};

// 2's complement in 130 bits, 26-bit radix
static rad26 minp26 = {5, 0, 0, 0, 0};

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

static void freeze32(mut32 h) {
    mut32 horig;
    ctr j = 0;

    for (j = 0; j < 5; ++j) {
        horig[j] = h[j];
    }

    add32(h, minp32);
    const uint32 neg = -(h[5] >> 31);

    for (j = 0; j < 5; ++j) {
        h[j] ^= neg & (horig[j] ^ h[j]);
    }
}

static void freeze26(mut26 h) {
    mut26 horig;
    ctr j = 0;

    for (j = 0; j < 5; ++j) {
        horig[j] = h[j];
    }

    add26(h, minp26);
    const uint32 neg = -(h[5] >> 25);

    for (j = 0; j < 5; ++j) {
        h[j] ^= neg & (horig[j] ^ h[j]);
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

static void mulmod32(mut32 h, rad32 r) {
    mut32 hr;
    ctr i = 0;
    ctr j = 0;

    // FIXME: doesn't fit. Needs uint96. Easy in assembly, hard in C.
    uint64 u;

    for (i = 0; i < 5; ++i) {
        u = 0;
        for (j = 0; j <= i; ++j) {
            u += h[j] * r[i - j];
        }

        // modular wraparound. 320 = 5 * 64 . 5 is for 2**130-5, but what is 64?
        // Answer: 2**(8-(130-128)). This is the "gap" Bernstein talks about.
        // TODO: check whether this needs adjusting for different radix
        // (probably not)
        for (j = i + 1; j < 5; ++j) {
            u += 320 * h[j] * r[i + 5 - j];
        }

        hr[i] = u;
    }

    for (i = 0; i < 5; ++i) {
        h[i] = hr[i];
    }

    squeeze32(h);
}

int crypto_onetimeauth_poly1305(unsigned char *out, const unsigned char *in,
                                unsigned long long inlen,
                                const unsigned char *k) {
    unsigned int j;
    unsigned int r[17];
    unsigned int h[17];
    unsigned int c[17];

    r[0] = k[0];
    r[1] = k[1];
    r[2] = k[2];
    r[3] = k[3] & 15;
    r[4] = k[4] & 252;
    r[5] = k[5];
    r[6] = k[6];
    r[7] = k[7] & 15;
    r[8] = k[8] & 252;
    r[9] = k[9];
    r[10] = k[10];
    r[11] = k[11] & 15;
    r[12] = k[12] & 252;
    r[13] = k[13];
    r[14] = k[14];
    r[15] = k[15] & 15;
    r[16] = 0;

    for (j = 0; j < 17; ++j) {
        h[j] = 0;
    }

    while (inlen > 0) {
        for (j = 0; j < 17; ++j) {
            c[j] = 0;
        }

        for (j = 0; (j < 16) && (j < inlen); ++j) {
            c[j] = in[j];
        }

        c[j] = 1;
        in += j;
        inlen -= j;
        add(h, c);
        mulmod(h, r);
    }

    freeze(h);

    for (j = 0; j < 16; ++j) {
        c[j] = k[j + 16];
    }

    c[16] = 0;
    add(h, c);

    for (j = 0; j < 16; ++j) {
        out[j] = h[j];
    }

    return 0;
}
