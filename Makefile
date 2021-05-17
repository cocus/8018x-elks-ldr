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

EXE = elksldr.bin

OBJS = \
	elksldr.o \
	# end of list
.PHONY : all clean

all: $(EXE).hex $(EXE)-rom.bin

$(EXE)-rom.bin: $(EXE)
	@echo "== creating ${ROMSIZE} bin image"
	@echo PAD=$(shell echo ${ROMSIZE}-$(shell stat --printf="%s" $(EXE)) | bc)
	@dd if=/dev/zero of=$(@) bs=$(shell echo ${ROMSIZE}-$(shell stat --printf="%s" $(EXE)) | bc) count=1
	@dd if=$(EXE) >> $(@)

$(EXE).hex: $(EXE)
	@echo "== BIN->HEX $< -> $(@)"
	@srec_cat $< -Binary -offset 0 -Output $@ -Intel

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) -M -o $(EXE) $(OBJS) > $(EXE).map

clean:
	rm -f $(EXE) $(OBJS) $(EXE).map
