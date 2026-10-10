// visual.s: a visual (full-screen) editor for Image BBS -- unfinished
//
// From Image BBS 2.0's visual.s ("code for a visual editor, unfinished"),
// on the 2.0 ML source disk 20ml-src.d81, by way of the text version in the
// 1.2/2.0 repo (v2/asm/tests/visual.asm). Converted to KickAssembler as it
// was, including what look like bugs (marked FIXME), so that it builds the
// same bytes as the original "++ visual" / "ml.visual".
//
// Load it as an ML module, then start it with &,16 (sys 49152): see
// core/tests/i.test visual.lbl. Lines are 3 bytes per column (reverse,
// colour, character) in the editor's line strings; Ctrl-V re-prints the
// lines, Ctrl-X stores them (putln) and exits. The line count is meant to
// be at $03fe ("lines" below), not kk.
//
// The &,nn calls it uses are reached through usetbl1 (lda #nn:jmp usetbl1).

.encoding "petscii_mixed"

#import "equat.s"

* = $c000 "visual.prg"

.label numx = $14
.label numy = $15

// state from the 2.0 source, not used yet:
//	modes = $03ff, lines = $03fe, cline = $03fb (current line?),
//	flags = $03fa, comm = $03f9, mline = $03f8, temp3 = $03f7,
//	case1 = $03f4, flag1 = $03f3

.label colors = $e8da		// KERNAL table of the 16 colour codes
// varbuf ($61, FAC1; "var" in the 2.0 source): varbuf+1/+2 point at a string

		jmp visual
// (the 2.0 source has this commented out: "jsr visual31:jmp visual2";
// visual31 doesn't exist, and visual2 re-prints the lines)

visual:
		lda #1
		sta editor
		ldy #0
// fill buf2 with 39 columns of {rvrs off}{white}" "
visual0:
		lda #$92	// {rvrs off}
		sta buf2,y
		iny
		lda #$05	// {white}
		sta buf2,y
		iny
		lda #' '
		sta buf2,y
		iny
		cpy #3*39
		bcc visual0
		sty index
		ldx #23
		stx numx
visual1:
		ldx numx
		jsr vputlnx
		dec numx
		bne visual1
		lda #1
		sta crsrc
		sta crsrx
		sta crsry
		lda #0
		sta crsrr
		lda #$93	// {clear}
		jsr xchrout
		jmp visual4

// Ctrl-V: clear the screen and print lines 1-23
visual2:
		lda #$93	// {clear}
		jsr xchrout
		ldx #1
		stx numx
visual3:
		ldx numx
		jsr prtln
		lda #13
		jsr xchrout
		inc numx
		ldx numx
		cpx #24
		bcc visual3

		jsr crsrpos
visual4:
		ldx crsry
		jsr getdes

// main loop: get a key
visual5:
		jsr xgetin
		pha
		and #$7f
		cmp #32
		pla
		bcc visual9	// a control character
// a printable character: store reverse, colour and character for this column
visual6:
		pha
		lda crsrx
		asl
		clc
		adc crsrx
		tay
		dey
		dey
		dey
		ldx crsrr
		lda revers,x
		sta (varbuf+1),y
		iny
		ldx crsrc
		lda colors,x
		sta (varbuf+1),y
		iny
		pla
		sta (varbuf+1),y
		jsr xchrout
		inc crsrx
		lda crsrx
		cmp #40
		bne visual5
// end of a line (or Return): go to the start of the next line
visual7:
		lda crsry
		cmp #23
		bcs visual8
		lda #13
		jsr xchrout
		lda #0
		sta crsrr
		lda #1
		sta crsrx
		inc crsry
		jmp visual4
// past the last line: back to the top
visual8:
		lda #1
		sta crsrx
		sta crsry
		lda #0
		sta crsrr
		lda #$13	// {home}
		jsr xchrout
		jmp visual4

// control characters
visual9:
		cmp #$91	// {up}
		bne visual10
		ldx crsry
		cpx #1
		beq visual10
		dec crsry
		jmp visual23
visual10:
		cmp #$11	// {down}
		bne visual11
		ldx crsry
		cpx #23
		beq visual11
		inc crsry
		jmp visual23

visual11:
		cmp #$1d	// {right}
		bne visual12
		ldx crsrx
		cpx #39
		beq visual12
		inc crsrx
		jmp visual23
visual12:
		cmp #$9d	// {left}
		bne visual13
		ldx crsrx
		cpx #1
		beq visual13
		dec crsrx
		jmp visual23

visual13:
		cmp #$93	// {clear}: start over
		bne visual14
		jmp visual
visual14:
		cmp #13		// Return
		bne visual15
		jmp visual7
visual15:
		cmp #$16	// Ctrl-V: re-print the lines
		bne visual16
		jmp visual2
visual16:
		cmp #$18	// Ctrl-X: store the lines and exit
		bne visual17
		jmp visual25
visual17:
		cmp #$12	// {rvrs on}
		bne visual18
		ldx #1
		jmp visual24
visual18:
		cmp #$92	// {rvrs off}
		bne visual19
		ldx #0
		jmp visual24
// a colour code? (colour 0, black, is never matched)
visual19:
		ldx #15
visual20:
		cmp colors,x
		beq visual21
		dex
		bne visual20
		jmp visual5
visual21:
		stx crsrc
		jsr xchrout
visual22:
		jsr xchrout
		jmp visual5

visual23:
		jsr xchrout
		jmp visual4

visual24:
		stx crsrr
		jmp visual22

// Ctrl-X: pack each line's 3-byte columns into buffer, keeping only the
// reverse/colour codes that change, and store it with putln
visual25:
		ldx #23
		sta numx	// FIXME: stx? A holds the Ctrl-X code ($18 = 24) here
		lda #0
		sta crsrc
visual26:
		ldx numx
		jsr getdes
		ldy #0
		ldx #0
		lda #$92	// {rvrs off}
		sta crsrr
visual27:
		lda (varbuf+1),y
		iny
		cmp crsrr
		beq visual28
		sta crsrr
		sta buffer,x
		inx
		cpx #80
		beq visual30
visual28:
		lda (varbuf+1),y
		iny
		cmp crsrc
		beq visual29
		sta crsrc
		sta buffer,x
		inx
		cpx #80
		beq visual30
visual29:
		lda (varbuf+1),y
		iny
		sta buffer,x
		inx
		cpx #80
		beq visual30
		cpy #3*39
		bcc visual27
visual30:
		stx index
		ldx numx
		jsr putln
		dec numx
		bne visual26
		rts

// & calls, by number, through usetbl1
getdes:
		lda #33		// &,33 getarr
		jmp usetbl1
putdes:
		lda #34		// &,34 putarr
		jmp usetbl1
xgetin:
		lda #23		// &,23 xgetin
		jmp usetbl1
xchrout1:
		lda #24		// &,24 xchrout1
		jmp usetbl1
putln:
		lda #36		// &,36 putln
		jmp usetbl1
prtln:
		lda #39		// &,39 prtln
		jmp usetbl1

xchrout:
		sta $fe
		pha
		jsr xchrout1
		pla
		rts

revers:
		.byte 18+128, 18	// {rvrs off}, {rvrs on}

// put the cursor at crsrx, crsry (both from 1)
crsrpos:
		lda #$13	// {home}
		jsr xchrout
		ldx crsry
		cpx #1
		beq crsrpos2
crsrpos1:
		lda #$11	// {down}
		jsr xchrout
		dex
		cpx #1
		bne crsrpos1
crsrpos2:
		ldx crsrx
		cpx #1
		beq crsrpos4
crsrpos3:
		lda #$1d	// {right}
		jsr xchrout
		dex
		cpx #1
		bne crsrpos3
crsrpos4:
		rts

// put and store string: line X = buf2 (index bytes)
vputlnx:
		txa
		pha
		lda 1
		pha
		lda #$37
		sta 1
		lda index
		jsr makerm1	// BASIC: make room for a string of A bytes
		pla
		sta 1
		ldy index
		beq vputln2
		dey
vputln1:
		lda buf2,y
		sta (varbuf+1),y
		dey
		bpl vputln1
vputln2:
		pla
		tax
		jmp putdes

crsrx:
		.byte 0		// cursor column (1-39)
crsry:
		.byte 0		// cursor line (1-23)
crsrc:
		.byte 0		// current colour (index into colors)
crsrr:
		.byte 0		// reverse: 0 off, 1 on
