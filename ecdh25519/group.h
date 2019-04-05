#ifndef GROUP_GE_H
#define GROUP_GE_H

#include "fe25519.h"

#define GROUP_GE_PACKEDBYTES 32

#define WINDOWSIZE 1
#define WINDOWMASK ((1 << WINDOWSIZE) - 1)

typedef struct {
    fe25519 x;
    fe25519 y;
    fe25519 z;
    fe25519 t;
} group_ge;

extern const group_ge group_ge_base;
extern const group_ge group_ge_neutral;

int group_ge_unpack(group_ge *r, const unsigned char x[GROUP_GE_PACKEDBYTES]);
void group_ge_pack(unsigned char r[GROUP_GE_PACKEDBYTES], const group_ge *x);

void group_ge_add(group_ge *r, const group_ge *x, const group_ge *y);
void group_ge_double(group_ge *r, const group_ge *x);
void group_ge_add_index(group_ge *gout, const group_ge *gin, int index);

#endif
