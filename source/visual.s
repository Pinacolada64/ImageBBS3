// visual.s: a visual (full-screen) editor for Image BBS -- unfinished
//
// From Image BBS 2.0's visual.s ("code for a visual editor, unfinished"),
// on the 2.0 ML source disk 20ml-src.d81, by way of the text version in the
// 1.2/2.0 repo (v2/asm/tests/visual.asm). Converted to KickAssembler (an
// exact conversion built the same bytes as "ml.visual" on 20ml-src.d81),
// then:
// - case conversion (the line editor's "case" flag) is turned off while
//   editing, so letters aren't forced to capitals;
// - control keys are looked up in a key table (keys/keyjmp), like the line
//   editor's (ctrlchrs/ctrl in swap1.s), with editing keys added: Delete,
//   Insert (Shift-Delete) and Ctrl-I, Ctrl-D, Ctrl-B, Ctrl-N, Ctrl-W.
// - Ctrl-X's line count is fixed (2.0 stored the key code, 24, not 23), and
//   Ctrl-X puts the number of lines used (the last one that isn't blank) in
//   "lines" ($03fe);
// - Ctrl-H shows a help screen of the keys.
//
// Load it as an ML module, then start it with &,16 (sys 49152): see
// core/tests/i.test visual.lbl. Lines are 3 bytes per column (reverse,
// colour, character) in the editor's line strings; Ctrl-V re-prints the
// lines, Ctrl-X stores them (putln), puts the number of lines used in
// $03fe ("lines"; not kk) and exits.
//
// The &,nn calls it uses are reached through usetbl1 (lda #nn:jmp usetbl1).

.encoding "petscii_mixed"

#import "equat.s"

* = $c000 "visual.prg"

.label numx = $14
.label numy = $15

// state from the 2.0 source, not used yet:
//	modes = $03ff, cline = $03fb (current line?),
//	flags = $03fa, comm = $03f9, mline = $03f8, temp3 = $03f7,
//	case1 = $03f4, flag1 = $03f3

.label colors = $e8da		// KERNAL table of the 16 colour codes
// varbuf ($61, FAC1; "var" in the 2.0 source): varbuf+1/+2 point at a string

		lda case	// the line editor's "convert to capitals" flag:
		sta savecase	// save it, and turn it off while editing
		lda #0
		sta case
		jmp visual
// (the 2.0 source had "jsr visual31:jmp visual2" here, commented out;
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
		ldx crsrr	// back to the current reverse and colour
		lda revers,x
		jsr xchrout
		ldx crsrc
		lda colors,x
		jsr xchrout

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

// control characters: look the key up in keys, jump through keyjmp
visual9:
		ldx #keyjmp-keys-1
vkey1:
		cmp keys,x
		beq vkey2
		dex
		bpl vkey1
		jmp visual19	// not in the table: a colour code?
vkey2:
		pha
		txa
		asl
		tax
		lda keyjmp,x
		sta vkeyjmp+1
		lda keyjmp+1,x
		sta vkeyjmp+2
		pla
vkeyjmp:
		jmp $ffff	// self-modified

keys:
		.byte $91, $11, $1d, $9d	// up, down, right, left
		.byte $93, 13, $16, $18		// Clear, Return, Ctrl-V, Ctrl-X
		.byte $12, $92			// RVS on, RVS off
		.byte $14, $94, $09		// Delete, Insert, Ctrl-I
		.byte $04, $02, $0e, $17	// Ctrl-D, Ctrl-B, Ctrl-N, Ctrl-W
		.byte $08			// Ctrl-H
keyjmp:
		.word kup, kdown, kright, kleft
		.word visual, visual7, visual2, visual25
		.word krvson, krvsoff
		.word kdelete, kinsert, kinsert
		.word kctrld, kctrlb, kctrln, kctrlw
		.word khelp

// cursor keys: move, and send the key itself
kup:
		ldx crsry
		cpx #1
		beq kignore
		dec crsry
		jmp visual23
kdown:
		ldx crsry
		cpx #23
		beq kignore
		inc crsry
		jmp visual23
kright:
		ldx crsrx
		cpx #39
		beq kignore
		inc crsrx
		jmp visual23
kleft:
		ldx crsrx
		cpx #1
		beq kignore
		dec crsrx
		jmp visual23
kignore:
		jmp visual5

krvson:
		ldx #1
		jmp visual24
krvsoff:
		ldx #0
		jmp visual24

// Delete: delete the character to the left of the cursor
kdelete:
		lda crsrx
		cmp #1
		beq kignore
		dec crsrx
		// fall through
// Ctrl-D: delete the character under the cursor
kctrld:
		lda crsrx
		jsr delcell
		jmp kredraw

// Insert, Ctrl-I: insert a space at the cursor (column 39 is lost)
kinsert:
		lda crsrx
		jsr inscell
		jmp kredraw

// Ctrl-B: delete from the start of the line to the cursor
kctrlb:
		lda crsrx
		cmp #1
		beq kignore
kctrlb1:
		lda #1
		jsr delcell
		dec crsrx
		lda crsrx
		cmp #1
		bne kctrlb1
		jmp kredraw1	// redraw the whole line

// Ctrl-N: move to the end of the line's text
kctrln:
		ldy #3*39-1	// the character of column 39
		ldx #39
kctrln1:
		lda (varbuf+1),y
		cmp #' '
		bne kctrln2
		dey
		dey
		dey
		dex
		bne kctrln1
kctrln2:
		inx		// just after the last character
		cpx #40
		bcc kctrln3
		ldx #39
kctrln3:
		stx crsrx
		jsr crsrpos
		jmp visual5

// Ctrl-W: delete the previous word (and any spaces after it)
kctrlw:
		lda crsrx
		cmp #1
		beq kctrlw3
		jsr prevchar
		cmp #' '
		bne kctrlw2
		dec crsrx	// a space before the cursor: delete it
		lda crsrx
		jsr delcell
		jmp kctrlw
kctrlw2:
		lda crsrx	// then the word's characters
		cmp #1
		beq kctrlw3
		jsr prevchar
		cmp #' '
		beq kctrlw3
		dec crsrx
		lda crsrx
		jsr delcell
		jmp kctrlw2
kctrlw3:
		jmp kredraw

// Ctrl-H: show the keys, wait for a key, then show the lines again
khelp:
		lda #<helptext
		sta vhelp+1
		lda #>helptext
		sta vhelp+2
vhelp:
		lda $ffff	// self-modified
		beq khelp2
		jsr xchrout
		inc vhelp+1
		bne vhelp
		inc vhelp+2
		jmp vhelp
khelp2:
		jsr xgetin
		jmp visual2

helptext:
		.byte $93, $05	// {clear}{white}
		.text "Visual editor keys:"
		.byte 13, 13
		.text "Cursor keys  move"
		.byte 13
		.text "Return       next line"
		.byte 13
		.text "Delete       delete to the left"
		.byte 13
		.text "Shift-Del    insert a space"
		.byte 13
		.text "Ctrl-I       insert a space"
		.byte 13
		.text "Ctrl-D       delete at the cursor"
		.byte 13
		.text "Ctrl-B       delete to line start"
		.byte 13
		.text "Ctrl-W       delete previous word"
		.byte 13
		.text "Ctrl-N       go to end of line"
		.byte 13
		.text "Rvs On/Off   reverse on/off"
		.byte 13
		.text "Colour keys  change colour"
		.byte 13
		.text "Ctrl-V       show the lines again"
		.byte 13
		.text "Clear        start over"
		.byte 13
		.text "Ctrl-X       done: save the lines"
		.byte 13
		.text "Ctrl-H       this help"
		.byte 13, 13
		.text "Press a key to go back."
		.byte 0

// redraw the line from the cursor (kredraw) or from column 1 (kredraw1)
kredraw:
		lda crsrx
		jsr redraw
		jmp visual5
kredraw1:
		lda #1
		jsr redraw
		jmp visual5

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
		stx numx	// was "sta numx" in 2.0, which stored the Ctrl-X code (24)
		lda #0
		sta crsrc
		sta lines	// the last line that isn't blank, found below
visual26:
		lda #0
		sta nonblank
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
		cmp #' '
		beq visual29a
		sta nonblank	// this line has something on it
visual29a:
		inx
		cpx #80
		beq visual30
		cpy #3*39
		bcc visual27
visual30:
		stx index
		ldx numx
		jsr putln
		lda lines	// lines go from 23 down: the first that isn't
		bne visual30a	// blank is the line count
		lda nonblank
		beq visual30a
		lda numx
		sta lines
visual30a:
		dec numx
		bne visual26
		lda savecase	// put the line editor's case setting back
		sta case
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

// --- line editing: each column of a line is 3 bytes at (varbuf+1),y:
// reverse, colour, character; column c (1-39) starts at y = 3*(c-1)

// column A -> y = 3*(A-1)
colofs:
		sta vtemp
		asl
		clc
		adc vtemp
		sec
		sbc #3
		tay
		rts

// the character in the column before the cursor
prevchar:
		lda crsrx
		jsr colofs
		dey		// the character byte of column crsrx-1
		lda (varbuf+1),y
		rts

// delete column A: columns A+1..39 move left, column 39 becomes a space
delcell:
		jsr colofs
delcell1:
		cpy #3*38
		bcs delcell2
		iny
		iny
		iny
		lda (varbuf+1),y
		dey
		dey
		dey
		sta (varbuf+1),y
		iny
		jmp delcell1
delcell2:
		ldy #3*38
		lda #$92	// {rvrs off}
		sta (varbuf+1),y
		iny
		lda #$05	// {white}
		sta (varbuf+1),y
		iny
		lda #' '
		sta (varbuf+1),y
		rts

// insert a space at column A, in the current reverse and colour: columns
// A..38 move right, and column 39 is lost
inscell:
		jsr colofs
		cpy #3*38	// column 39: nothing to move, just replace it
		bcs inscell2
		sty vtemp
		ldy #3*38-1	// the last byte of column 38
inscell1:
		lda (varbuf+1),y
		iny
		iny
		iny
		sta (varbuf+1),y
		dey
		dey
		dey
		cpy vtemp
		beq inscell2
		dey
		jmp inscell1
inscell2:
		ldx crsrr
		lda revers,x
		sta (varbuf+1),y
		iny
		ldx crsrc
		lda colors,x
		sta (varbuf+1),y
		iny
		lda #' '
		sta (varbuf+1),y
		rts

// redraw columns A..39 of the line on screen, each in its own reverse and
// colour; then go back to the current reverse/colour and to the cursor
redraw:
		pha
		ldx crsrx
		stx vtemp2
		sta crsrx
		jsr crsrpos	// to column A
		lda vtemp2
		sta crsrx
		pla
		jsr colofs
redraw1:
		sty vtemp
		lda (varbuf+1),y	// reverse
		jsr xchrout
		ldy vtemp
		iny
		lda (varbuf+1),y	// colour
		jsr xchrout
		ldy vtemp
		iny
		iny
		lda (varbuf+1),y	// character
		jsr xchrout
		ldy vtemp
		iny
		iny
		iny
		cpy #3*39
		bcc redraw1
		ldx crsrr
		lda revers,x
		jsr xchrout
		ldx crsrc
		lda colors,x
		jsr xchrout
		jmp crsrpos

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
savecase:
		.byte 0		// the line editor's case flag, saved while editing
vtemp:
		.byte 0
vtemp2:
		.byte 0
nonblank:
		.byte 0		// non-zero: the line being saved isn't blank
