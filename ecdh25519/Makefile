OPENCM3_DIR ?= ../libopencm3
LDSCRIPT   = $(OPENCM3_DIR)/lib/stm32/f4/stm32f405x6.ld
LIBNAME    = opencm3_stm32f4
ARCH_FLAGS = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEFINES    = -DSTM32F4
OBJS       = stm32f4_wrapper.o

all: ecdh25519test.bin ecdh25519test.lst  \
		 ecdh25519speed.bin ecdh25519speed.lst


ecdh25519test.elf: fe25519.o fe25519.h group.o group.h smult.o smult.h test.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ test.o fe25519.o group.o smult.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

ecdh25519speed.elf: fe25519.o fe25519.h group.o group.h smult.o smult.h speed.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ speed.o fe25519.o group.o smult.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

fe25519.o: fe25519.h
group.o: group.h fe25519.h
smult.o: smult.h group.h fe25519.h

fe25519_test: fe25519.c fe25519.h fe25519_test.c
	clang -Wall -Wextra -o $@ fe25519.c fe25519_test.c

include ../common/make.mk
