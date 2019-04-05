# Crypto Engineering Software Assignment

- Lars Jellema, s4388747
- Sal Wolffs, s4064542

## chacha20

Most of our effort has been spent on doing the 20 rounds as efficiently as
possible, worrying less about the overhead in calling the chacha20 core function
and returning from it. Inlining and optimization there would likely close the
gap with the theoretical lower bound, but with much worse return on investment
than optimizing the inner loop. 

Still, some optimization has been attempted in the outer loop, reducing the
outer loop doing the calls to the chacha20 core to 5 instructions, with somewhat
disappointing gains. Additionally, we've added an align directive to the
assembly around the inner loop, which produced a decent speed gain for such a
trivial change.

Concretely, for the inner loop, we've partly unrolled the inner loop, going
through it in chunks of 4 rounds, which yields a total rotation of 0 mod 32 on
the fourth row, saving us all explicit rotations for that row. The rounds and
quarterrounds have also all been inlined, making the entire chacha20 core a
single function. Of course, we also do almost all of our rotations inline, which
chacha20 seems to be designed for. Finally, the loop counter was made to count
down instead of up, allowing it to be decremented and tested in a single
instruction, and it is loaded and stored when a register happens to be free
anyway (during a switch), saving a store/load to make space for it.

### State management

The chacha20 state is 16 words in size, while only 14 word-size registers are
available even if we free the lr register by pushing its contents on stack.
Therefore, we need to make space for two extra words by swapping. The easiest
way to accomplish this is by having four words share two registers, which is
what we did. 

Since every round needs to be access every element of the state,
the shared registers must be switch which value they contain at least once
during each round. And due to the shape of the result dependency graph, it's
impossible to interleave rounds so as to have them share this switching effort.
So each round needs to perform its own register swap. 

We can limit ourselves to a single 2-register swap per round by observing that
while rounds are forced into serial computation by dependencies, the
quarterrounds within a round are completely independent. Therefore, we can
rearrange them as we like without affecting the result. Additionally, each
quarterround takes a different word from each row. So the design is to have just
one row in the shared registers and rearrange quarterrounds within rounds such
that whichever words happen to be loaded by the previous round are used first,
avoiding the need to load/store at the beginning or end of a round.

### Lower bounds

Each quarterround requires at least 8 instructions of one cycle each, for 32
cycles per round. Halfway through each round there is a swap of registers, which
we think is optimal, costing 2 instructions of 4 cycles each, for another 8
cycles per round. So each round costs a minimum of 40 cycles, giving 800 cycles
per 20. This ignores the cost of maintaining the loop counter and jumping,
because those could be optimized out.

Adding the original values back in requires loads, since with one or two
exceptions the values are either not constant or too complex to handle as
immediate values. 16 original values to load at the same time as their mixed
counterparts (so two sets) means at least 3 batches (2 would imply holding twice
eight values in registers, and we can only hold 14), giving 6 cycles of ldm
overhead plus 16 cycles of actual loading, 16 of adding, at least 4 cycles of
stm overhead (more likely 6) to write the results out, and 16 cycles of actually
writing those results. Any solution is also going to require making space for
the original values in registers, which we haven't analysed but almost certainly
requires at least 10 cycles for storing and later loading mixing output. In
total, the post-processing therefore increases our lower bound by at least
$6+16+16+4+16+10 = 68$ cycles at a very conservative estimate.

Most, but not all, of the costs before entering the inner loop can be avoided
by thoroughly breaking the C ABI in the chacha20 core, having the inner and
outer loop interact more intimately. One step further would be completely
inlining the inner loop in the outer, eliminating all calls. We did not expend
this effort, but will be estimating the call overhead as 0 to be sure we don't
overestimate. This is certainly an underestimation, but underestimations of
lower bounds are still valid lower bounds.

The above costs are per call to the chacha20 core, which produces 64 bytes per
call, meaning it takes 16 calls to produce 1024 bytes. In total, that gives us a
lower bound of $868 * 16 = 13888$ cycles. This is an underestimation, but since
we reached 16524 cycles in practice, this is enough to show there can't be
more than about $10-20%$ to be gained from further optimization, most of it likely
in increasingly obfuscating adjustments. Since further optimizations would
require large amounts of programmer time to win increasingly small amounts of
cpu time, we decided to leave it there. 

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
rewrite the functions in assembly one by one. We updated smult.c to use a window
size of 4, which also made that part of the code run in constant time. With more
time, we would have written all of fe25519.c in assembly.

We measure a final improvement in cycle count from around 45 million to around
12 million, about a factor of 3. There are still many possibilities for further
optimization, ecdh25519 is too large to fully optimize within 1ec.
