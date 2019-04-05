# Crypto Engineering Software Assignment

- Lars Jellema, s4388747
- Sal Wolffs, s4064542

## chacha20

We rewrote chacha20 in assembly. Its state is 16 register in size, while only 14
registers are available. We minimized swapping by swapping only two registers
once per round. Each round consists of 16 adds and 16 eors, all of which first
rotate their second operand into the right position, and a 2-register load
multiple and store multiple for swapping. We expect that each round takes 38
cycles, but we didn't verify this. We unrolled 4 rounds because this makes most
of the rotates add up to 0, reducing the number of correctional rotates needed
at the end. We expect that fixing these rotates and looping back takes another
10 cycles, for a total of 810 cycles for 20 rounds.

We didn't spend as much effort on the pre- and post-amble of chacha20. We
optimized the outer loop of the stream to 5 instructions although this is mostly
because the chacha20 function does all the heavy lifting. We gained a
significant number of cycles by making sure the 32-bit instructions were
aligned.

We believe that our code is within a factor of 2 from optimal. There are
probably no gains possible within the inner loop, apart from fully unrolling,
but some are still possible around it. We reached 16526 cycles for 1024 bytes,
an improvement factor of 3.

## poly1305

We rewrote poly1305 in assembly. We chose to use 26-bit limbs because this left
enough space to accumulate all five limb products. We don't fully reduce the
state in the loop, it is only reduced far enough to avoid overflowing the 32-bit
words. We avoid reduction after the addition completely. We keep both operands
of the multiplication in registers, while computing the output limbs one by one
and writing them to the stack. The operands take up 10 registers, a 64-bit
accumulator and a loop counter take up 3 more, and the last register is used for
multiplication by 5 and for storing the result.

We assume the upper half of the stream length is not used, because if it were
nonzero, it would imply that the buffer is larger than addressable memory.

We believe that our code is within a factor of 2 from optimal. There are still
some cycles that can be optimized, but we chose to keep them for the sake of
code clarity. Our final measured speed was 3915 cycles for 512 bytes, or
slightly below 8 cycles per byte, an improvement factor of 42.

## ecdh25519

We rewrote fe25519.c to mostly generalize it over the limb size. We then
chose 24-bits limbs because they're fairly large and made it easy to convert the
literals. By rewriting the C to an acceptable limb size, we made it possible to
rewrite the functions in assembly one by one.

With more time, we would have implemented fixed windows of 4 bits and have
written all of fe25519.c in assembly.

Just changing the limb size reduced the cycle count from around 45 million to
around 12 million, about a factor of 3.
