-: setup offset vimregisters
:let @e=0:let @f=0


q: quarterround
o    add Ra, Rb, rol #"=(@e+0)%32pa
    eor Rd, Ra, ror #"=(@f+0)%32pa
    add Rc, Rd, rol #"=(@f+8)%32pa
    eor Rb, Rc, ror #"=(@e+0)%32pa
    add Ra, Rb, rol #"=(@e+12)%32pa
    eor Rd, Ra, ror #"=(@f+8)%32pa
    add Rc, Rd, rol #"=(@f+24)%32pa
    eor Rb, Rc, ror #"=(@e+12)%32pV7k

v: vertical round
@q
:'<,'>s/Ra/\='r' . (@r+0)%16/g
:'<,'>s/Rb/\='r' . (@r+4)%16/g
:'<,'>s/Rc/\='r' . (@r+8)%16/g
:'<,'>s/Rd/\='r' . (@r+12)%16/g'>ok

d: diagonal round
@q
:'<,'>s/Ra/\='r' . (@r+0)%16/g
:'<,'>s/Rb/\='r' . (@r+5)%16/g
:'<,'>s/Rc/\='r' . (@r+10)%16/g
:'<,'>s/Rd/\='r' . (@r+15)%16/g'>ok

jj0"iy$
i: increment base register
m`:let @r=(@r+1)%4

jj0"jy$
j: increment rotation offsets after one round
m`:let @e=(@e+19)%32:let @f=(@f+24)%32

s: switch to x14, x15 active
o    stmia sp, {r12,r13}
    ldmdb sp, {r12,r13} # now r12=x14, r13=x15
k
   
t: switch back to x12, x13
o    stmdb sp, {r12,r13} 
    ldmia sp, {r12,r13} # now r12=x12, r13=x13
k

g: generate doubleround
:let @r=0@v@i@v@i@s@v@i@v@ja# switch to diagonal.
# note that diagonal rounds are independent: we're doing the last one
# first, because it's loaded. Then the first, then load x12, x13 and
# do the second and third:@d@i@d@i@t@d@i@d@j


