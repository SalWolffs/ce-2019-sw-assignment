jj0"my$
m: meta-macro, loads the macro whose header is under the cursor and positions you on next macro
0"ly$@l}j

:let @e=0:let @f=0
-: setup offset vimregisters
:let @e=0:let @f=0

jj0v}k$h"qy
q: quarterround
A
    add Ra, Ra, Rb, ror #=(0+@e)%32
    eor Rd, Rd, Ra, ror #=(32-@f)%32
    add Rc, Rc, Rd, ror #=(16+@f)%32
    eor Rb, Rb, Rc, ror #=(32-@e)%32
    add Ra, Ra, Rb, ror #=(12+@e)%32
    eor Rd, Rd, Ra, ror #=(48-@f)%32
    add Rc, Rc, Rd, ror #=(24+@f)%32
    eor Rb, Rb, Rc, ror #=(52-@e)%32V7k

jj0"ay$
a: ad-hoc fix for rol not being a valid inline shift op
m`"ndwr-:let @n=(32-@n)%32+32"nP``

jj0v}k$h"vy
v: vertical round
@q
:'<,'>s/Ra/\='r' . (@r+0)/gk
:'<,'>s/Rb/\='r' . (@r+4)/gk
:'<,'>s/Rc/\='r' . (@r+8)/gk
:'<,'>s/Rd/\='x' . (@r+12)/g'>o

jj0v}k$h"dy
d: diagonal round
@q
:'<,'>s/Ra/\='r' . ((@r+0)%4+0)/gk
:'<,'>s/Rb/\='r' . ((@r+1)%4+4)/gk
:'<,'>s/Rc/\='r' . ((@r+2)%4+8)/gk
:'<,'>s/Rd/\='x' . ((@r+3)%4+12)/g'>o

jj0"iy$
i: increment base register
m`:let @r=(@r+1)%4

jj0"jy$
j: increment rotation offsets after one round
m`:let @e=(@e+19)%32:let @f=(@f+24)%32

jj0v}k$h"sy
s: switch to x14, x15 active
o    stmia sp, {r12,r14}
    ldmdb sp, {r12,r14} 
        # now r12=x14, r14=x15
k

jj0v}k$h"ty
t: switch back to x12, x14
o    stmdb sp, {r12,r14} 
    ldmia sp, {r12,r14} 
        # now r12=x12, r14=x13
k

jj0v}k$h"gy
g: generate doubleround
:let @r=0@v@i@v@i@s@v@i@v@ja
# switch to diagonal.
# note that quarterrounds are independent: we're doing the last one
# first, because it's loaded. Then the first, then load x12, x13 and
# do the second and third:@d@i@d@i@t@d@i@d@j

