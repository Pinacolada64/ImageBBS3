#import "equat.s"

* = $02a7 "boot.prg"

// the boot program!

// put back correct basic main loop address

boot:
		lda #<$a483
		sta $302
		lda #>$a483
		sta $303

// our screen colors

		lda #$00
		sta $d020
		sta $d021
		lda #clear_screen
		jsr $e716

// kernal messages off

		jsr $ff90

// load the ml

		lda #fileend - file
		ldx #<file
		ldy #>file
		jsr $ffbd
		lda #1
		sta $b9
		lda #0
		jsr $ffd5

// run it

		jsr $a533
		lda #0
		jsr $a871
		jmp $a7ae

// the filename for the ml file

file:
		.encoding "petscii_mixed"
		.text "image " + version_number
fileend:

		.fill $0300 - *, 0 

// the boot vector

		.word $e38b, boot
