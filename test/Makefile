all: speed.bin

include ../common/make.mk

speed.elf: speed.o benchmark.o $(OBJS) $(LDSCRIPT)
	$(LD) -o $@ speed.o benchmark.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

benchmark.o: benchmark.s
	$(CC) $(CFLAGS) -o $@ -c $<
