OPENCM3_DIR ?= ../libopencm3
LDSCRIPT   = $(OPENCM3_DIR)/lib/stm32/f4/stm32f405x6.ld
LIBNAME    = opencm3_stm32f4
ARCH_FLAGS = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEFINES    = -DSTM32F4
OBJS       = stm32f4_wrapper.o
ASMS       = chacha20.s stream.s

all: chacha20test.bin chacha20test.lst \
		 chacha20speed.bin chacha20speed.lst


chacha20test.elf: $(ASMS) chacha20.h test.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ test.o $(ASMS) $(OBJS) $(LDFLAGS) -l$(LIBNAME)

chacha20speed.elf: $(ASMS) chacha20.h speed.o $(OBJS) $(LDSCRIPT)
		$(LD) -o $@ speed.o $(ASMS) $(OBJS) $(LDFLAGS) -l$(LIBNAME)


include ../common/make.mk


