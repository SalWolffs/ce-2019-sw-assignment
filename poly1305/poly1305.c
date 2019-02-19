/*
20080912
D. J. Bernstein
Public domain.
*/

#include "poly1305.h"

static void add(unsigned int h[17],const unsigned int c[17])
{   // little-endian bytewise addition on 136 bits
  unsigned int j; // loop counter
  unsigned int u; // buffer for local result (8 bits) and carry (1 bit). 32 bits.
  u = 0;
  for (j = 0;j < 17;++j) { u += h[j] + c[j]; h[j] = u & 255; u >>= 8; }
}

static void squeeze(unsigned int h[17])
{
  unsigned int j; // loop counter
  unsigned int u; // result buffer
  u = 0;
  for (j = 0;j < 16;++j) { u += h[j]; h[j] = u & 255; u >>= 8; }
    // Carry loop on first 128 bits.
  u += h[16]; h[16] = u & 3;
    // Add with carry on last 2 bits. Keep overflow in u.
  u = 5 * (u >> 2); 
    // For every 2**130 we cut off, add 5 back to stay equal mod 2**130-5 .
  for (j = 0;j < 16;++j) { u += h[j]; h[j] = u & 255; u >>= 8; }
    // Carry on first 128 bits.
  u += h[16]; h[16] = u;
    // leave final carry in top byte. Note: this is reduced, but not uniquely
    // so in mod 2**130-5: 2**130-1 written as 
    // 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x3
    // would remain that way, while in mod 2**130-5 it equals 4
}

static const unsigned int minusp[17] = {
  5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 252
} ;

static void freeze(unsigned int h[17])
{
  unsigned int horig[17];
  unsigned int j;
  unsigned int negative;
  for (j = 0;j < 17;++j) horig[j] = h[j];
  add(h,minusp);
  negative = -(h[16] >> 7);
  for (j = 0;j < 17;++j) h[j] ^= negative & (horig[j] ^ h[j]);
}

static void mulmod(unsigned int h[17],const unsigned int r[17])
{
  unsigned int hr[17];
  unsigned int i;
  unsigned int j;
  unsigned int u;

  for (i = 0;i < 17;++i) {
    u = 0;
    for (j = 0;j <= i;++j) u += h[j] * r[i - j];
    for (j = i + 1;j < 17;++j) u += 320 * h[j] * r[i + 17 - j];
    hr[i] = u;
  }
  for (i = 0;i < 17;++i) h[i] = hr[i];
  squeeze(h);
}

int crypto_onetimeauth_poly1305(unsigned char *out,const unsigned char *in,unsigned long long inlen,const unsigned char *k)
{
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

  for (j = 0;j < 17;++j) h[j] = 0;

  while (inlen > 0) {
    for (j = 0;j < 17;++j) c[j] = 0;
    for (j = 0;(j < 16) && (j < inlen);++j) c[j] = in[j];
    c[j] = 1;
    in += j; inlen -= j;
    add(h,c);
    mulmod(h,r);
  }

  freeze(h);

  for (j = 0;j < 16;++j) c[j] = k[j + 16];
  c[16] = 0;
  add(h,c);
  for (j = 0;j < 16;++j) out[j] = h[j];
  return 0;
}
