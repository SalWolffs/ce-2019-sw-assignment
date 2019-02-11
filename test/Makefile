OPENCM3_DIR ?= ../libopencm3
LDSCRIPT   = $(OPENCM3_DIR)/lib/stm32/f4/stm32f405x6.ld
LIBNAME    = opencm3_stm32f4
ARCH_FLAGS = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEFINES    = -DSTM32F4
OBJS       = ../common/stm32f4_wrapper.o

all: speed.bin

speed.elf: speed.o benchmark.o $(OBJS) $(LDSCRIPT)
	$(LD) -o $@ speed.o benchmark.o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

benchmark.o: benchmark.s
	$(CC) $(CFLAGS) -o $@ -c $<

include ../common/make.mk
