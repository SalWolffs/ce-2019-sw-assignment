# Poly1305

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
slightly below 8 cycles per byte, an improvement by a factor of 42.
