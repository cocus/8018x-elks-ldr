# Based off SYS86 project (https://github.oom/mfld-fr/sys86)
# Global Makefile

CC = ia16-elf-gcc
AS = ia16-elf-as
LD = ia16-elf-ld

ROMPRG = ../elks/elkscmd/or566flash/build/romprg
ROMPRG_TTY = /dev/ttyUSB0

# Path for the elks Image
ELKS_IMAGE = ../elks2/elks/elks/arch/i86/boot/Image
# Path for the elks romfs.bin
ELKS_ROMFS = ../elks2/elks/image/romfs.bin

# set to 1 if you want to dump the PCB values on startup
USE_PCBDUMP = 0

# set to 0 if you don't have LEDs on address 0xXXX2 of GCS6
HAS_LEDS = 1

# set to 1 if you have a NE2K card connected on GCS4
HAS_NE2K = 1

# set to 0 if you don't have a bq3285 on GCS2
HAS_BQ3285 = 1

# which flash part should be used when flashing eeproms using the minipro
FLASH_PART = MBM29F040

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

OBJS_PCBDUMP = \
	pcbdump.o \
	# end of list

OBJS = \
	elksldr.o \
	8018x-serial.o \
	# end of list

ifeq ($(USE_PCBDUMP), 1)
	OBJS += $(OBJS_PCBDUMP)
	DEFINES += -DUSING_PCBDUMP
endif

ifeq ($(HAS_LEDS), 1)
	DEFINES += -DHAS_LEDS
endif

ifeq ($(HAS_NE2K), 1)
	DEFINES += -DHAS_NE2K
endif

ifeq ($(HAS_BQ3285), 1)
	DEFINES += -DHAS_BQ3285
endif

.PHONY : all clean

all: $(EXE).hex

flash: rom
	minipro -p $(FLASH_PART) -w $(EXE)-rom.bin

romprog-loader:
	@echo "== romprog erase chip"
	@$(ROMPRG) $(ROMPRG_TTY) erase chip
	@echo "== romprog flash loader"
	@$(ROMPRG) $(ROMPRG_TTY) write ${ROM_LOADER_OFFSET} $(EXE)

romprog-elks:
	@echo "== romprog erase chip"
	@$(ROMPRG) $(ROMPRG_TTY) erase chip
	@echo "== romprog flash elks image"
	@$(ROMPRG) $(ROMPRG_TTY) write ${ROM_ELKS_IMAGE_OFFSET} $(ELKS_IMAGE)

romprog-romfs:
	@echo "== romprog erase chip"
	@$(ROMPRG) $(ROMPRG_TTY) erase chip
	@echo "== romprog flash romfs.bin"
	@$(ROMPRG) $(ROMPRG_TTY) write ${ROM_ELKS_ROMFS_OFFSET} $(ELKS_ROMFS)

romprog: $(EXE) $(ELKS_IMAGE) $(ELKS_ROMFS)
	@echo "== romprog ping"
	@$(ROMPRG) $(ROMPRG_TTY) ping
	@echo "== romprog id"
	@$(ROMPRG) $(ROMPRG_TTY) id
	@echo "== romprog erase chip"
	@$(ROMPRG) $(ROMPRG_TTY) erase chip
	@echo "== romprog flash loader"
	@$(ROMPRG) $(ROMPRG_TTY) write ${ROM_LOADER_OFFSET} $(EXE)
	@echo "== romprog flash elks image"
	@$(ROMPRG) $(ROMPRG_TTY) write ${ROM_ELKS_IMAGE_OFFSET} $(ELKS_IMAGE)
	@echo "== romprog flash romfs.bin"
	@$(ROMPRG) $(ROMPRG_TTY) write ${ROM_ELKS_ROMFS_OFFSET} $(ELKS_ROMFS)


rom: $(EXE).hex $(EXE)-rom.bin memusage

memusage: $(EXE) $(ELKS_IMAGE) $(ELKS_ROMFS)
	$(eval ELKS_IMAGE_SIZE := $(shell stat -L -c %s $(ELKS_IMAGE)))
	$(eval ELKS_ROMFS_SIZE := $(shell stat -L -c %s $(ELKS_ROMFS)))
	$(eval ROM_LOADER_SIZE := $(shell stat -L -c %s $(EXE)))

	$(eval ELKS_IMAGE_MAX_SIZE := $(shell expr $(ROM_LOADER_AT) - $(ROM_ELKS_IMAGE_AT)))
	$(eval ELKS_ROMFS_MAX_SIZE := $(shell expr $(ROM_ELKS_IMAGE_AT) - $(ROM_ELKS_ROMFS_AT)))
	$(eval ROM_LOADER_MAX_SIZE := $(shell expr 1048576 - $(ROM_LOADER_AT)))

	$(eval ELKS_IMAGE_SIZE_PERCENTAGE := $(shell echo "${ELKS_IMAGE_SIZE}*100/${ELKS_IMAGE_MAX_SIZE}" | bc))
	$(eval ELKS_ROMFS_SIZE_PERCENTAGE := $(shell echo "${ELKS_ROMFS_SIZE}*100/${ELKS_ROMFS_MAX_SIZE}" | bc))
	$(eval ROM_LOADER_SIZE_PERCENTAGE := $(shell echo "${ROM_LOADER_SIZE}*100/${ROM_LOADER_MAX_SIZE}" | bc))

	@echo "== memory usage:"
	@echo "ELKS_IMAGE ${ELKS_IMAGE_SIZE_PERCENTAGE}%, ${ELKS_IMAGE_SIZE} out of ${ELKS_IMAGE_MAX_SIZE} bytes"
	@echo "ELKS_ROMFS ${ELKS_ROMFS_SIZE_PERCENTAGE}%, ${ELKS_ROMFS_SIZE} out of ${ELKS_ROMFS_MAX_SIZE} bytes"
	@echo "ROM_LOADER ${ROM_LOADER_SIZE_PERCENTAGE}%, ${ROM_LOADER_SIZE} out of ${ROM_LOADER_MAX_SIZE} bytes"

# Image and romfs.bin come directly from ELKS build
$(EXE)-rom.bin: $(EXE) $(ELKS_IMAGE) $(ELKS_ROMFS)
	@echo "== creating ${ROMSIZE} ROM image"
	@dd if=/dev/zero of=$(@) bs=${ROMSIZE} count=1
	@echo " Adding $(EXE) at ${ROM_LOADER_OFFSET}"
	@dd conv=notrunc if=$(EXE) of=$(@) bs=1 seek=${ROM_LOADER_OFFSET}
	@echo " Adding Image at ${ROM_ELKS_IMAGE_OFFSET}"
	@dd conv=notrunc if=$(ELKS_IMAGE) of=$(@) bs=1 seek=${ROM_ELKS_IMAGE_OFFSET}
	@echo " Adding romfs.bin at ${ROM_ELKS_ROMFS_OFFSET}"
	@dd conv=notrunc if=$(ELKS_ROMFS) of=$(@) bs=1 seek=${ROM_ELKS_ROMFS_OFFSET}

$(EXE).hex: $(EXE)
	@echo "== BIN->HEX $< -> $(@)"
	@srec_cat $< -Binary -offset 0 -Output $@ -Intel
	@echo " loader size" $(shell stat --printf="%s" $(EXE)) "bytes"

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) -M -o $(EXE) $(OBJS) > $(EXE).map

clean:
	rm -f $(EXE) $(EXE)-rom.bin $(OBJS) $(EXE).map
