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

static void add26(uint32 h[5], const uint32 c[5]) {
    for (ctr j = 0; j < 5; ++j) {
        h[j] += c[j];
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

// 2's complement in 130 bits, 26-bit radix
static rad26 minp26 = {5, 0, 0, 0, 0};

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

extern void mulmod26(uint32 h[5], const uint32 r[5]);

// This function assumes little endian memory layout.
int poly1305_26(unsigned char *out, const unsigned char *in,
                unsigned long long inlen, const unsigned char *k) {
    uint32 r[5], h[5], c[5];
    uint32 *out_words = (uint32 *)out;

    r[0] = (*(uint32 *)(k + 0) & 0x03ffffff) >> 0;
    r[1] = (*(uint32 *)(k + 3) & 0x0ffffc0c) >> 2;
    r[2] = (*(uint32 *)(k + 6) & 0x3ffc0ff0) >> 4;
    r[3] = (*(uint32 *)(k + 9) & 0xfc0fffc0) >> 6;
    r[4] = (*(uint32 *)(k + 12) & 0x0fffff00) >> 8;

    h[0] = h[1] = h[2] = h[3] = h[4] = 0;

    while (inlen > 0) {
        c[0] = c[1] = c[2] = c[3] = c[4] = 0;
        // TODO: Load c from in and update in and inlen

        // Assertion: h[1] < 2L, h[0,2,3,4] < L
        add26(h, c);
        // Assertion: h[1] < 3L, h[0,2,3,4] < 2L
        mulmod26(h, r);
        // Assertion: h[1] < 2L, h[0,2,3,4] < L
    }

    // TODO: Set c to upper half of k

    add26(h, c);

    // TODO: Fully reduce h modulo p

    out_words[0] = h[0] | h[1] << 26;
    out_words[1] = h[1] >> 6 | h[2] << 20;
    out_words[2] = h[2] >> 12 | h[3] << 14;
    out_words[3] = h[3] >> 18 | h[4] << 8;

    return 0;
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

    // h = 0
    for (j = 0; j < 17; ++j) {
        h[j] = 0;
    }

    while (inlen > 0) {
        // c = 0
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
