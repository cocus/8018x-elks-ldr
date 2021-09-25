# Based off SYS86 project (https://github.oom/mfld-fr/sys86)
# Global Makefile

CC = ia16-elf-gcc
AS = ia16-elf-as
LD = ia16-elf-ld

BUILDSTAMP = $(shell date)
DEFINES += -DBUILD_TIMESTAMP='"$(BUILDSTAMP)"'

CFLAGS = -ffunction-sections -Werror -ffreestanding -O1 -std=gnu99 -mtune=i80186 -march=i80186 $(DEFINES)
ASFLAGS = -ffreestanding -O1 -std=gnu99 -nostdinc -mtune=i80186 -march=i80186 $(DEFINES)
LDFLAGS = -nostdlib -T elksldr.ld

ROMSIZE = 524288 # 512kB
ROM_ELKS_IMAGE_AT = 917504 # 0xe0000
ROM_ELKS_ROMFS_AT = 524288 # 0x80000
ROM_LOADER_AT = 1044480 # 0xff000
FLASH_START = $(shell expr 1048576 - $(ROMSIZE)) # 1M - ROMSIZE
ROM_ELKS_IMAGE_OFFSET = $(shell expr $(ROM_ELKS_IMAGE_AT) - $(ROMSIZE))
ROM_ELKS_ROMFS_OFFSET = $(shell expr $(ROM_ELKS_ROMFS_AT) - $(ROMSIZE))
ROM_LOADER_OFFSET = $(shell expr $(ROM_LOADER_AT) - $(ROMSIZE))

EXE = elksldr.bin

OBJS = \
	elksldr.o \
	# end of list
.PHONY : all clean

all: $(EXE).hex

flash: rom
	minipro -p MBM29F040 -w $(EXE)-rom.bin

rom: $(EXE).hex $(EXE)-rom.bin

# Image and romfs.bin come directly from ELKS build
$(EXE)-rom.bin: $(EXE)
	@echo "== creating ${ROMSIZE} ROM image"
	@dd if=/dev/zero of=$(@) bs=${ROMSIZE} count=1
	@echo " Adding $(EXE) at ${ROM_LOADER_OFFSET}"
	@dd conv=notrunc if=$(EXE) of=$(@) bs=1 seek=${ROM_LOADER_OFFSET}

$(EXE).hex: $(EXE)
	@echo "== BIN->HEX $< -> $(@)"
	@srec_cat $< -Binary -offset 0 -Output $@ -Intel
	@echo " loader size" $(shell stat --printf="%s" $(EXE)) "bytes"

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) -M -o $(EXE) $(OBJS) > $(EXE).map

clean:
	rm -f $(EXE) $(EXE)-rom.bin $(OBJS) $(EXE).map
