all: poly1305test.bin poly1305speed.bin

include ../common/make.mk

poly1305test.elf: poly1305.o poly1305.h test.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ test.o poly1305.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

poly1305speed.elf: poly1305.o poly1305.h speed.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ speed.o poly1305.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)
