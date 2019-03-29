#include "fe25519.h"
#include <stdio.h>

// NOTE: pack and unpack are NOT generalized over the following parameters.
#define LIMB_COUNT 11
#define USED_BITS 24
#define USED_BITS_FINAL 15
#define LIMB_COUNT_MUL (2 * LIMB_COUNT - 1)
#define FINAL_LIMB (LIMB_COUNT - 1)
#define USED_BITS_DIFF (USED_BITS - USED_BITS_FINAL)
#define USED_MASK ((1 << USED_BITS) - 1)
#define USED_MASK_FINAL ((1 << USED_BITS_FINAL) - 1)
#define FIRST_LIMB_MAX (USED_MASK - 18)

#if 0
#define WINDOWSIZE 1 /* Should be 1,2, or 4 */
#define WINDOWMASK ((1 << WINDOWSIZE) - 1)
#endif

const fe25519 fe25519_zero = {{0}};
const fe25519 fe25519_one = {{1}};
const fe25519 fe25519_two = {{2}};

/* sqrt(-1) */
const fe25519 fe25519_sqrtm1 = {{0x0EA0B0, 0x1B274A, 0x78C4EE, 0xAD2FE4,
                                 0x431806, 0xD7A72F, 0x993DFB, 0x2B4D00,
                                 0xC1DF0B, 0x24804F, 0x2B83}};

/* -sqrt(-1) */
const fe25519 fe25519_msqrtm1 = {{0xF15F3D, 0xE4D8B5, 0x873B11, 0x52D01B,
                                  0xBCE7F9, 0x2858D0, 0x66C204, 0xD4B2FF,
                                  0x3E20F4, 0xDB7FB0, 0x547C}};

/* -1 */
const fe25519 fe25519_m1 = {{0xffffec, 0xffffff, 0xffffff, 0xffffff, 0xffffff,
                             0xffffff, 0xffffff, 0xffffff, 0xffffff, 0xffffff,
                             0x7fff}};

static uint32_t equal(uint32_t a, uint32_t b) { /* 16-bit inputs */
    uint32_t x = a ^ b;                         /* 0: yes; 1..65535: no */
    x -= 1;   /* 4294967295: yes; 0..65534: no */
    x >>= 31; /* 1: yes; 0: no */
    return x;
}

static uint32_t ge(uint32_t a, uint32_t b) { /* 16-bit inputs */
    uint32_t x = a;
    x -= b;   /* 0..65535: yes; 4294901761..4294967295: no */
    x >>= 31; /* 0: yes; 1: no */
    x ^= 1;   /* 1: yes; 0: no */
    return x;
}

static void reduce(fe25519 *r) {
    uint32_t t;
    int i;

    t = r->v[FINAL_LIMB] >> USED_BITS_FINAL;
    r->v[FINAL_LIMB] &= USED_MASK_FINAL;
    t *= 19;
    r->v[0] += t;
    for (i = 0; i < FINAL_LIMB; i++) {
        t = r->v[i] >> USED_BITS;
        r->v[i + 1] += t;
        r->v[i] &= USED_MASK;
    }
}

/* reduction modulo 2^255-19 */
void fe25519_freeze(fe25519 *r) {
    int i;
    reduce(r);
    reduce(r);
    uint32_t m = ge(r->v[0], FIRST_LIMB_MAX);
    for (i = 1; i < FINAL_LIMB; i++)
        m &= equal(r->v[i], USED_MASK);
    m &= equal(r->v[FINAL_LIMB], USED_MASK_FINAL);

    m = -m;

    r->v[0] -= m & FIRST_LIMB_MAX;
    for (i = 1; i < FINAL_LIMB; i++)
        r->v[i] -= m & USED_MASK;
    r->v[FINAL_LIMB] -= m & USED_MASK_FINAL;
}

void fe25519_unpack(fe25519 *r, const unsigned char x[32]) {
    int i;
    for (i = 0; i < FINAL_LIMB; i++) {
        r->v[i] = x[3 * i];
        r->v[i] |= (uint32_t)x[3 * i + 1] << 8;
        r->v[i] |= (uint32_t)x[3 * i + 2] << 16;
    }

    r->v[FINAL_LIMB] = x[30] | ((uint32_t)x[31] << 8);
    r->v[FINAL_LIMB] &= USED_MASK_FINAL;
}

/* Assumes input x being reduced below 2^255 */
void fe25519_pack(unsigned char r[32], const fe25519 *x) {
    int i;
    fe25519 y = *x;
    fe25519_freeze(&y);

    for (i = 0; i < FINAL_LIMB; i++) {
        r[3 * i] = y.v[i];
        r[3 * i + 1] = y.v[i] >> 8;
        r[3 * i + 2] = y.v[i] >> 16;
    }

    r[30] = y.v[FINAL_LIMB];
    r[31] = y.v[FINAL_LIMB] >> 8;
}

int fe25519_iszero(const fe25519 *x) { return fe25519_iseq(x, &fe25519_zero); }

int fe25519_isone(const fe25519 *x) { return fe25519_iseq(x, &fe25519_one); }

// return true if x has LSB set
int fe25519_isnegative(const fe25519 *x) {
    fe25519 t = *x;

    fe25519_freeze(&t);

    return t.v[0] & 1;
}

int fe25519_iseq(const fe25519 *x, const fe25519 *y) {
    fe25519 t1, t2;
    int i, r = 0;

    t1 = *x;
    t2 = *y;
    fe25519_freeze(&t1);
    fe25519_freeze(&t2);
    for (i = 0; i < LIMB_COUNT; i++)
        r |= (1 - equal(t1.v[i], t2.v[i]));
    return 1 - r;
}

void fe25519_cmov(fe25519 *r, const fe25519 *x, unsigned char b) {
    fe25519 diff;
    int i;

    for (i = 0; i < LIMB_COUNT; i++)
        diff.v[i] = r->v[i] ^ x->v[i];

    uint32_t mask = -b;

    for (i = 0; i < LIMB_COUNT; i++)
        r->v[i] ^= diff.v[i] & mask;
}

void fe25519_neg(fe25519 *r, const fe25519 *x) {
    fe25519 t = fe25519_zero;
    fe25519_sub(r, &t, x);
}

void fe25519_add(fe25519 *r, const fe25519 *x, const fe25519 *y) {
    int i;
    for (i = 0; i < LIMB_COUNT; i++)
        r->v[i] = x->v[i] + y->v[i];
    reduce(r);
}

void fe25519_double(fe25519 *r, const fe25519 *x) {
    int i;
    for (i = 0; i < LIMB_COUNT; i++)
        r->v[i] = 2 * x->v[i];
    reduce(r);
}

void fe25519_sub(fe25519 *r, const fe25519 *x, const fe25519 *y) {
    int i;
    uint32_t t[LIMB_COUNT];
    t[0] = x->v[0] + (2 * FIRST_LIMB_MAX);
    t[FINAL_LIMB] = x->v[FINAL_LIMB] + (2 * USED_MASK_FINAL);
    for (i = 1; i < FINAL_LIMB; i++)
        t[i] = x->v[i] + (2 * USED_MASK);
    for (i = 0; i < LIMB_COUNT; i++)
        r->v[i] = t[i] - y->v[i];
    reduce(r);
}

void fe25519_mul(fe25519 *o, const fe25519 *x, const fe25519 *y) {
    int i, j;
    uint64_t t[LIMB_COUNT_MUL] = {0};
    uint32_t r[LIMB_COUNT + 2] = {0};
    uint64_t limb;

    for (i = 0; i < LIMB_COUNT; i++)
        for (j = 0; j < LIMB_COUNT; j++)
            t[i + j] += x->v[i] * y->v[j];

    for (i = 0; i < LIMB_COUNT; i++) {
        r[i] += t[i] & USED_MASK;
        r[i + 1] += t[i] >> USED_BITS;
    }

    for (i = 0; i < FINAL_LIMB; i++) {
        limb = 19 * t[i + LIMB_COUNT];
        r[i] += (limb << USED_BITS_DIFF) & USED_MASK;
        r[i + 1] += (limb >> USED_BITS_FINAL) & USED_MASK;
        r[i + 2] += limb >> (USED_BITS + USED_BITS_FINAL);
    }

    r[0] += r[LIMB_COUNT];
    r[1] += r[LIMB_COUNT + 1];

    for (i = 0; i < LIMB_COUNT; i++)
        o->v[i] = r[i];
    reduce(o);
}

void fe25519_square(fe25519 *o, const fe25519 *x) {
    int i, j;
    uint64_t t[LIMB_COUNT_MUL] = {0};
    uint32_t r[LIMB_COUNT + 2] = {0};
    uint64_t limb;

    for (i = 0; i < LIMB_COUNT; i++)
        t[i + i] += x->v[i] * x->v[i];

    for (i = 0; i < LIMB_COUNT; i++)
        for (j = 0; j < i; j++)
            t[i + j] += 2 * x->v[i] * x->v[j];

    for (i = 0; i < LIMB_COUNT; i++) {
        r[i] += t[i] & USED_MASK;
        r[i + 1] += t[i] >> USED_BITS;
    }

    for (i = 0; i < FINAL_LIMB; i++) {
        limb = 19 * t[i + LIMB_COUNT];
        r[i] += (limb << USED_BITS_DIFF) & USED_MASK;
        r[i + 1] += (limb >> USED_BITS_FINAL) & USED_MASK;
        r[i + 2] += limb >> (USED_BITS + USED_BITS_FINAL);
    }

    r[0] += r[LIMB_COUNT];
    r[1] += r[LIMB_COUNT + 1];

    for (i = 0; i < LIMB_COUNT; i++)
        o->v[i] = r[i];
    reduce(o);
}

#if 0
void fe25519_invert(fe25519 *r, const fe25519 *x)
{
	fe25519 z2;
	fe25519 z9;
	fe25519 z11;
	fe25519 z2_5_0;
	fe25519 z2_10_0;
	fe25519 z2_20_0;
	fe25519 z2_50_0;
	fe25519 z2_100_0;
	fe25519 t0;
	fe25519 t1;
	int i;
	
	/* 2 */ fe25519_square(&z2,x);
	/* 4 */ fe25519_square(&t1,&z2);
	/* 8 */ fe25519_square(&t0,&t1);
	/* 9 */ fe25519_mul(&z9,&t0,x);
	/* 11 */ fe25519_mul(&z11,&z9,&z2);
	/* 22 */ fe25519_square(&t0,&z11);
	/* 2^5 - 2^0 = 31 */ fe25519_mul(&z2_5_0,&t0,&z9);

	/* 2^6 - 2^1 */ fe25519_square(&t0,&z2_5_0);
	/* 2^7 - 2^2 */ fe25519_square(&t1,&t0);
	/* 2^8 - 2^3 */ fe25519_square(&t0,&t1);
	/* 2^9 - 2^4 */ fe25519_square(&t1,&t0);
	/* 2^10 - 2^5 */ fe25519_square(&t0,&t1);
	/* 2^10 - 2^0 */ fe25519_mul(&z2_10_0,&t0,&z2_5_0);

	/* 2^11 - 2^1 */ fe25519_square(&t0,&z2_10_0);
	/* 2^12 - 2^2 */ fe25519_square(&t1,&t0);
	/* 2^20 - 2^10 */ for (i = 2;i < 10;i += 2) { fe25519_square(&t0,&t1); fe25519_square(&t1,&t0); }
	/* 2^20 - 2^0 */ fe25519_mul(&z2_20_0,&t1,&z2_10_0);

	/* 2^21 - 2^1 */ fe25519_square(&t0,&z2_20_0);
	/* 2^22 - 2^2 */ fe25519_square(&t1,&t0);
	/* 2^40 - 2^20 */ for (i = 2;i < 20;i += 2) { fe25519_square(&t0,&t1); fe25519_square(&t1,&t0); }
	/* 2^40 - 2^0 */ fe25519_mul(&t0,&t1,&z2_20_0);

	/* 2^41 - 2^1 */ fe25519_square(&t1,&t0);
	/* 2^42 - 2^2 */ fe25519_square(&t0,&t1);
	/* 2^50 - 2^10 */ for (i = 2;i < 10;i += 2) { fe25519_square(&t1,&t0); fe25519_square(&t0,&t1); }
	/* 2^50 - 2^0 */ fe25519_mul(&z2_50_0,&t0,&z2_10_0);

	/* 2^51 - 2^1 */ fe25519_square(&t0,&z2_50_0);
	/* 2^52 - 2^2 */ fe25519_square(&t1,&t0);
	/* 2^100 - 2^50 */ for (i = 2;i < 50;i += 2) { fe25519_square(&t0,&t1); fe25519_square(&t1,&t0); }
	/* 2^100 - 2^0 */ fe25519_mul(&z2_100_0,&t1,&z2_50_0);

	/* 2^101 - 2^1 */ fe25519_square(&t1,&z2_100_0);
	/* 2^102 - 2^2 */ fe25519_square(&t0,&t1);
	/* 2^200 - 2^100 */ for (i = 2;i < 100;i += 2) { fe25519_square(&t1,&t0); fe25519_square(&t0,&t1); }
	/* 2^200 - 2^0 */ fe25519_mul(&t1,&t0,&z2_100_0);

	/* 2^201 - 2^1 */ fe25519_square(&t0,&t1);
	/* 2^202 - 2^2 */ fe25519_square(&t1,&t0);
	/* 2^250 - 2^50 */ for (i = 2;i < 50;i += 2) { fe25519_square(&t0,&t1); fe25519_square(&t1,&t0); }
	/* 2^250 - 2^0 */ fe25519_mul(&t0,&t1,&z2_50_0);

	/* 2^251 - 2^1 */ fe25519_square(&t1,&t0);
	/* 2^252 - 2^2 */ fe25519_square(&t0,&t1);
	/* 2^253 - 2^3 */ fe25519_square(&t1,&t0);
	/* 2^254 - 2^4 */ fe25519_square(&t0,&t1);
	/* 2^255 - 2^5 */ fe25519_square(&t1,&t0);
	/* 2^255 - 21 */ fe25519_mul(r,&t1,&z11);
}
#endif

void fe25519_pow2523(fe25519 *r, const fe25519 *x) {
    fe25519 z2;
    fe25519 z9;
    fe25519 z11;
    fe25519 z2_5_0;
    fe25519 z2_10_0;
    fe25519 z2_20_0;
    fe25519 z2_50_0;
    fe25519 z2_100_0;
    fe25519 t;
    int i;

    /* 2 */ fe25519_square(&z2, x);
    /* 4 */ fe25519_square(&t, &z2);
    /* 8 */ fe25519_square(&t, &t);
    /* 9 */ fe25519_mul(&z9, &t, x);
    /* 11 */ fe25519_mul(&z11, &z9, &z2);
    /* 22 */ fe25519_square(&t, &z11);
    /* 2^5 - 2^0 = 31 */ fe25519_mul(&z2_5_0, &t, &z9);

    /* 2^6 - 2^1 */ fe25519_square(&t, &z2_5_0);
    /* 2^10 - 2^5 */ for (i = 1; i < 5; i++) { fe25519_square(&t, &t); }
    /* 2^10 - 2^0 */ fe25519_mul(&z2_10_0, &t, &z2_5_0);

    /* 2^11 - 2^1 */ fe25519_square(&t, &z2_10_0);
    /* 2^20 - 2^10 */ for (i = 1; i < 10; i++) { fe25519_square(&t, &t); }
    /* 2^20 - 2^0 */ fe25519_mul(&z2_20_0, &t, &z2_10_0);

    /* 2^21 - 2^1 */ fe25519_square(&t, &z2_20_0);
    /* 2^40 - 2^20 */ for (i = 1; i < 20; i++) { fe25519_square(&t, &t); }
    /* 2^40 - 2^0 */ fe25519_mul(&t, &t, &z2_20_0);

    /* 2^41 - 2^1 */ fe25519_square(&t, &t);
    /* 2^50 - 2^10 */ for (i = 1; i < 10; i++) { fe25519_square(&t, &t); }
    /* 2^50 - 2^0 */ fe25519_mul(&z2_50_0, &t, &z2_10_0);

    /* 2^51 - 2^1 */ fe25519_square(&t, &z2_50_0);
    /* 2^100 - 2^50 */ for (i = 1; i < 50; i++) { fe25519_square(&t, &t); }
    /* 2^100 - 2^0 */ fe25519_mul(&z2_100_0, &t, &z2_50_0);

    /* 2^101 - 2^1 */ fe25519_square(&t, &z2_100_0);
    /* 2^200 - 2^100 */ for (i = 1; i < 100; i++) { fe25519_square(&t, &t); }
    /* 2^200 - 2^0 */ fe25519_mul(&t, &t, &z2_100_0);

    /* 2^201 - 2^1 */ fe25519_square(&t, &t);
    /* 2^250 - 2^50 */ for (i = 1; i < 50; i++) { fe25519_square(&t, &t); }
    /* 2^250 - 2^0 */ fe25519_mul(&t, &t, &z2_50_0);

    /* 2^251 - 2^1 */ fe25519_square(&t, &t);
    /* 2^252 - 2^2 */ fe25519_square(&t, &t);
    /* 2^252 - 3 */ fe25519_mul(r, &t, x);
}

void fe25519_invsqrt(fe25519 *r, const fe25519 *x) {
    fe25519 den2, den3, den6, chk, t, t2;
    int b;

    fe25519_square(&den2, x);
    fe25519_mul(&den3, &den2, x);

    fe25519_square(&den6, &den3);
    fe25519_mul(&t, &den6, x); // r is now x^7

    fe25519_pow2523(&t, &t);
    fe25519_mul(&t, &t, &den3);

    fe25519_square(&chk, &t);
    fe25519_mul(&chk, &chk, x);

    fe25519_mul(&t2, &t, &fe25519_sqrtm1);
    b = 1 - fe25519_isone(&chk);

    fe25519_cmov(&t, &t2, b);

    *r = t;
}
