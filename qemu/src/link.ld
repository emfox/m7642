/* link.ld -- the fake kernel is linked at physical addresses.
 * IMAGE_BASE is supplied with --defsym so gen.py stays the only place that
 * knows the address space. */
ENTRY(_start)
PHDRS { all PT_LOAD FLAGS(7); }
SECTIONS
{
  . = IMAGE_BASE + 0x00000;
  .text.start : { *(.text.start) } :all
  . = IMAGE_BASE + 0x00800;
  .vectors : { *(.vectors) } :all
  . = IMAGE_BASE + 0x01000;
  .fake : { *(.fake) } :all
  . = IMAGE_BASE + 0x01400;
  .benchstr : { *(.benchstr) } :all
  . = IMAGE_BASE + 0x02000;
  .text.boot : { *(.text.boot) } :all
  . = IMAGE_BASE + 0x20000;
  .tramp : { *(.tramp) } :all
  . = IMAGE_BASE + 0x30200;
  .pad : { *(.pad) } :all
  . = IMAGE_BASE + 0x34000;
  .padstr : { *(.padstr) } :all
  . = IMAGE_BASE + 0x90000;
  .stack : { *(.stack) } :all
  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) *(.ARM.attributes*) }
}
