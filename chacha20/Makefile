all: chacha20test.bin chacha20speed.bin

include ../common/make.mk

chacha20test.elf: chacha20.o quadround.o chacha20.h test.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ test.o chacha20.o quadround.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

chacha20speed.elf: chacha20.o quadround.o chacha20.h speed.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ speed.o chacha20.o quadround.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

quadround.o: quadround.s
	$(CC) $(CFLAGS) -o $@ -c $<
