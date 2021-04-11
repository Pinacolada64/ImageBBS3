; boot 3.0

; -d64:D64Name::PRGNAME
; cannot combine both -prg and -d64 output in same command line?
; c64list4_04.exe "boot 3_0.asm" -prg
; C64List4_04.exe "boot 3_0.prg" -d64:test::"BOOT 3.0" -verbose

; c64list hello.bas -d64:"hello::@0:HELLO" -ovr

; starts at the beginning of the processor stack
	orig $02a7

; the boot program!

; put back correct BASIC main loop address

boot:
	lda #<$a483
	sta $302
	lda #>$a483
	sta $303

; our screen colors

	lda #$00
	sta $d020
	sta $d021
	lda #'{clear}'	; clear_screen
	jsr $e716

; kernal messages off

	lda #$00	; added by pinacolada (.a gets set to something else after jsr $e716)
	jsr $ff90

; load the ml

	lda #filename_length
	ldx #<file
	ldy #>file
	jsr $ffbd
	lda #1
	sta $b9
	lda #0
	jsr $ffd5

; run it

	jsr $a533	; relink BASIC prg
	lda #0
	jsr $a871
	jmp $a7ae

; the filename for the ml file

file:
	ascii "image 3.0"
filename_length = * - file

; write $00 bytes from * to start of vector table at $300
	align $100,$00

; the boot vector

	word $e38b, boot
