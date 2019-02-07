jj0"my$
m: meta-macro, loads the macro whose header is under the cursor and positions you on next macro
0"ly$@l}j

:let @e=0:let @f=0
-: setup offset vimregisters
:let @e=0:let @f=0

jj0v}k$h"qy
q: quarterround
o    add Ra, Rb, rol #=(@e+0)%32
    eor Rd, Ra, ror #=(@f+0)%32
    add Rc, Rd, rol #=(@f+8)%32
    eor Rb, Rc, ror #=(@e+0)%32
    add Ra, Rb, rol #=(@e+12)%32
    eor Rd, Ra, ror #=(@f+8)%32
    add Rc, Rd, rol #=(@f+24)%32
    eor Rb, Rc, ror #=(@e+12)%32V7k

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
o    stmia sp, {r12,r13}
    ldmdb sp, {r12,r13} # now r12=x14, r13=x15
k

jj0v}k$h"ty
t: switch back to x12, x13
o    stmdb sp, {r12,r13} 
    ldmia sp, {r12,r13} # now r12=x12, r13=x13
k

jj0v}k$h"gy
g: generate doubleround
:let @r=0@v@i@v@i@s@v@i@v@ja# switch to diagonal.
# note that quarterrounds are independent: we're doing the last one
# first, because it's loaded. Then the first, then load x12, x13 and
# do the second and third:@d@i@d@i@t@d@i@d@j

