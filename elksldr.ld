OUTPUT_FORMAT(binary)
OUTPUT_ARCH(i386)
ENTRY(_init8018x_and_start)

/*
 * On startup the 8018X sets the UCS so it uses the last 1K segment before 1MB.
 * Main code will be placed there. No R/W sections are used (not needed).
 */
SECTIONS {
    . = 0x0;
    /* with a CS=0xf000, this should land on 0xf0000+0xff00 = 0xfff00 */
    .text 0xff00 : AT(0xff00) {
        *(.text);
        *(.rodata*);
    }

    /* with a CS=0xf000, this should land on 0xf0000+0xfff0 = 0xffff0 */
    .reset 0xfff0 : AT(0xfff0) {
        *(.reset.text);
    }

    /* Throw away everything else. */
    /DISCARD/ : { *(*) }
}