#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "fe25519.h"

typedef uint8_t u8;
typedef uint32_t u32;

const u8 v0[32] = {0xb1, 0x7a, 0xa0, 0x76, 0x93, 0xd7, 0x8d, 0x70,
                   0xfb, 0x44, 0x3a, 0x5b, 0xf1, 0xc6, 0x90, 0xe2,
                   0xc3, 0x79, 0x39, 0x6f, 0x56, 0xac, 0xc5, 0x5f,
                   0xb5, 0xfc, 0x1c, 0xc5, 0x58, 0xa2, 0xd9, 0x85};

const u8 v1[32] = {0xba, 0xdb, 0xc5, 0x8f, 0xc7, 0x97, 0x18, 0xc4,
                   0x78, 0x32, 0x13, 0x0a, 0x94, 0x2c, 0x80, 0xdb,
                   0x77, 0x84, 0x34, 0xdc, 0x04, 0xce, 0x19, 0x16,
                   0xda, 0xe4, 0x16, 0x36, 0x06, 0xca, 0xdd, 0x30};

const u8 v0_plus_v1[32] = {0x6b, 0x56, 0x66, 0x06, 0x5b, 0x6f, 0xa6, 0x34,
                           0x74, 0x77, 0x4d, 0x65, 0x85, 0xf3, 0x10, 0xbe,
                           0x3b, 0xfe, 0x6d, 0x4b, 0x5b, 0x7a, 0xdf, 0x75,
                           0x8f, 0xe1, 0x33, 0xfb, 0x5e, 0x6c, 0xb7, 0x36};

const u8 v0_minus_v1[32] = {0xe4, 0x9e, 0xda, 0xe6, 0xcb, 0x3f, 0x75, 0xac,
                            0x82, 0x12, 0x27, 0x51, 0x5d, 0x9a, 0x10, 0x07,
                            0x4c, 0xf5, 0x04, 0x93, 0x51, 0xde, 0xab, 0x49,
                            0xdb, 0x17, 0x06, 0x8f, 0x52, 0xd8, 0xfb, 0x54};

const u8 v0_times_v1[32] = {0xac, 0xde, 0x06, 0xd5, 0xe1, 0xa5, 0x71, 0x89,
                            0xb0, 0x31, 0x35, 0x97, 0x4c, 0x3b, 0x30, 0xf8,
                            0x18, 0xca, 0x54, 0x2b, 0xcf, 0x75, 0xb2, 0x30,
                            0xbc, 0x75, 0xa9, 0x43, 0x6c, 0xbd, 0x94, 0x11};

int main_result;

void assert_reduced(fe25519 *x) {
    bool reduced = x->v[FINAL_LIMB] <= 0xffff;
    for (int i = 0; i < FINAL_LIMB; i++) {
        reduced &= x->v[i] <= USED_MASK;
    }

    if (!reduced) {
        main_result = 1;
        printf("Not reduced!\n");
    }
}

void print_vec(const u8 *a, char *msg) {
    printf("%s:", msg);
    for (int i = 28; i >= 0; i -= 4) {
        printf(" %02x%02x%02x%02x", a[i + 3], a[i + 2], a[i + 1], a[i]);
    }
    printf("\n");
}

void assert_vec_eq(const u8 *a, const u8 *b, char *msg) {
    bool equal = true;
    for (size_t i = 0; i < 32; i++) {
        if (a[i] != b[i]) {
            equal = false;
            main_result = 1;
        }
    }

    if (!equal) {
        print_vec(a, msg);
        print_vec(b, msg);
    }
}

void pack_test() {
    fe25519 unpacked;
    u8 packed[32];

    fe25519_unpack(&unpacked, v1);
    fe25519_pack(packed, &unpacked);

    assert_vec_eq(v1, packed, "pack");
}

void reduce_test() {
    fe25519 max = {{0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                    0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
                    0xffffffff}};

    fe25519_reduce(&max);
    assert_reduced(&max);
}

void add_test() {
    fe25519 f0;
    fe25519 f1;
    fe25519 f0_plus_f1;
    u8 packed[32];

    fe25519_unpack(&f0, v0);
    fe25519_unpack(&f1, v1);
    fe25519_add(&f0_plus_f1, &f0, &f1);
    fe25519_pack(packed, &f0_plus_f1);

    assert_reduced(&f0);
    assert_reduced(&f1);
    assert_reduced(&f0_plus_f1);
    assert_vec_eq(v0_plus_v1, packed, "add");
}

void sub_test() {
    fe25519 f0;
    fe25519 f1;
    fe25519 f0_minus_f1;
    u8 packed[32];

    fe25519_unpack(&f0, v0);
    fe25519_unpack(&f1, v1);
    fe25519_sub(&f0_minus_f1, &f0, &f1);
    fe25519_pack(packed, &f0_minus_f1);

    assert_reduced(&f0);
    assert_reduced(&f1);
    assert_reduced(&f0_minus_f1);
    assert_vec_eq(v0_minus_v1, packed, "sub");
}

void mul_test() {
    fe25519 f0;
    fe25519 f1;
    fe25519 f0_times_f1;
    u8 packed[32];

    fe25519_unpack(&f0, v0);
    fe25519_unpack(&f1, v1);
    fe25519_mul(&f0_times_f1, &f0, &f1);
    fe25519_pack(packed, &f0_times_f1);

    assert_reduced(&f0);
    assert_reduced(&f1);
    assert_reduced(&f0_times_f1);
    assert_vec_eq(v0_times_v1, packed, "mul");
}

int main() {
    main_result = 0;

    pack_test();
    add_test();
    sub_test();
    mul_test();

    if (main_result == 0) {
        printf("All tests passed!\n");
    }

    return main_result;
}
