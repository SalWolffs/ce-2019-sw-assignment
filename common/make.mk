# This file contains common Makefile content for all platforms;
# it is referenced from the individual Makefiles

OPENCM3_DIR ?= ../libopencm3
LDSCRIPT    = $(OPENCM3_DIR)/lib/stm32/f4/stm32f405x6.ld
LIBNAME     = opencm3_stm32f4
ARCH_FLAGS  = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEFINES     = -DSTM32F4
OBJS        = ../common/stm32f4_wrapper.o

PREFIX	?= arm-none-eabi
CC		= $(PREFIX)-gcc
LD		= $(PREFIX)-gcc
OBJCOPY	= $(PREFIX)-objcopy
OBJDUMP	= $(PREFIX)-objdump
GDB		= $(PREFIX)-gdb

CFLAGS		+= -O3 \
		   -Wall -Wextra -Wimplicit-function-declaration \
		   -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes \
		   -Wundef -Wshadow \
		   -I$(OPENCM3_DIR)/include \
		   -fno-common $(ARCH_FLAGS) -MD $(DEFINES)
LDFLAGS		+= --static -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group \
		   -T$(LDSCRIPT) -nostartfiles -Wl,--gc-sections,--print-gc-sections \
		   $(ARCH_FLAGS) \
		   -L$(OPENCM3_DIR)/lib

lib:
	@if [ ! "`ls -A $(OPENCM3_DIR)`" ] ; then \
		printf "######## ERROR ########\n"; \
		printf "\tlibopencm3 is not initialized.\n"; \
		printf "\tPlease run (in the root directory):\n"; \
		printf "\t$$ git submodule init\n"; \
		printf "\t$$ git submodule update\n"; \
		printf "\tbefore running make.\n"; \
		printf "######## ERROR ########\n"; \
		exit 1; \
		fi
	make -C $(OPENCM3_DIR)

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

%.elf: %.o $(OBJS) $(LDSCRIPT)
	$(LD) -o $(*).elf $(*).o $(OBJS) $(LDFLAGS) -l$(LIBNAME)

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

clean:
	find . -name \*.o -type f -exec rm -f {} \;
	find . -name \*.d -type f -exec rm -f {} \;
	rm -f *.elf
	rm -f *.bin
