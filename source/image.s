.encoding "petscii_mixed"

#import "equat.s"

* = $0801 "image.prg"

.label scnmem = $0400
.label chrmem = $2000
.label colmem = $d800

.label chrpok = chrmem/1024 + 16*scnmem/1024

.label devnum = 186

.label src = $fb
.label dst = $fd

		// link to next line (bogus, gets fixed by basic loader)
		.byte $1b, $1b
		// line number
    	.word 1990
		// "sys" token
	    .byte $9e
        .text toIntString(start)
		.text " "
		// "new" token
		.byte $a2
		.text " image software"
		// end of basic line
        .byte 0
		// end of basic program
		.word 0 

* = $081e

chrset:
		.import c64 "chr.imagelogo"

scndat:
		.import c64 "scn.imagelogo"

coldat:
		.import c64 "col.imagelogo"

start:
		lda #0
		sta $d020
		lda #1
		sta $d021
		lda #11
		sta $d011

		ldx #<chrset
		ldy #>chrset
		stx src
		sty src+1
		ldx #<chrmem
		ldy #>chrmem
		stx dst
		sty dst+1
		ldx #8
		jsr move

		ldx #<scndat
		ldy #>scndat
		stx src
		sty src+1
		ldx #<scnmem
		ldy #>scnmem
		stx dst
		sty dst+1
		ldx #4
		jsr move

		ldx #<coldat
		ldy #>coldat
		stx src
		sty src+1
		ldx #<colmem
		ldy #>colmem
		stx dst
		sty dst+1
		ldx #4
		jsr move

		lda #chrpok
		sta $d018
		lda #27
		sta $d011

		jsr boot
		jmp $c000

		lda #11
		sta $d011
		lda #$17
		sta $d018
		lda #clear_screen
		jsr $e716
		lda #27
		sta $d011
		jmp $a8f8

move:
		ldy #0
loop:
		lda (src),y
		sta (dst),y
		iny
		bne loop
		inc src+1
		inc dst+1
		dex
		bne loop
		rts

file1:
		.text "ml " + version_number
file1_end:

boot:
		ldy #17
		lda #96
fill_loop:
		sta rs232,y
		dey
		bpl fill_loop
// load "ml"
		lda #file1_end - file1
		ldx #<file1
		ldy #>file1
		jsr $ffbd
		lda #1
		ldx devnum
		ldy #1
		jsr $ffba
		lda #0
		jmp $ffd5
