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
// - Ctrl-H shows a help screen of the keys;
// - lines are packed (pack) for saving and for the screen: a reverse or
//   colour code only where it changes, no colour code for plain spaces,
//   and no blanks after the last visible column;
// - the cursor is tracked (xchrout keeps curx/cury), and crsrpos moves it
//   the cheaper way: from where it is with cursor keys, or from Home;
// - a lost carrier or expired time saves the lines and leaves (xgetin then
//   returns Return forever, which 2.0 obeyed), and the chat key starts chat.
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
		lda #$ff	// where the cursor is isn't known (++ visual stays
		sta curx	// in memory between runs); the Clear below sets it
		sta cury
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
		lda #$ff	// the colour isn't known yet; it carries on from
		sta lastc	// line to line
		ldx #1
		stx numx
visual3:
		ldx numx
		jsr getdes
		jsr lastcol
		sta pend
		lda #$92	// {rvrs off}: a carriage return turns reverse off
		sta lastr
		lda #1
		jsr pack
		jsr outbuf
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
// xgetin returns Return (13) on every call once the carrier is lost, time
// runs out or the sysop's chat key is hit, so check those first (as the
// line editor does in swap1.s)
		jsr carchk	// 0: OK, 1: carrier lost, 2: time up
		cmp #0
		beq visual5a
		pla
		jmp visual25	// save the lines and leave, as Ctrl-X does
visual5a:
		jsr chatchk
		cmp #0
		beq visual5b
		pla
		jsr chatmode	// the sysop wants to chat: do that, then
		jmp visual2	// show the lines again
visual5b:
		pla
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
		jsr markold
		lda crsrx
		cmp #1
		beq kignore
		dec crsrx
		// fall through
// Ctrl-D: delete the character under the cursor
kctrld:
		jsr markold
		lda crsrx
		jsr delcell
		jmp kredraw

// Insert, Ctrl-I: insert a space at the cursor (column 39 is lost)
kinsert:
		jsr markold
		lda crsrx
		jsr inscell
		jmp kredraw

// Ctrl-B: delete from the start of the line to the cursor
kctrlb:
		jsr markold
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
		jsr markold
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

// Ctrl-X: store each line packed (pack), and put the number of lines used
// (the last one that isn't blank) in "lines"
visual25:
		ldx #23
		stx numx	// was "sta numx" in 2.0, which stored the Ctrl-X code (24)
		lda #0
		sta lines
visual26:
		ldx numx
		jsr getdes
		jsr lastcol
		sta pend
		beq visual27	// a blank line
		lda lines	// lines go from 23 down: the first that isn't
		bne visual27	// blank is the line count
		lda numx
		sta lines
visual27:
		lda #$92	// {rvrs off}: a line starts with reverse off
		sta lastr
		lda #$ff	// and with no colour known: the first one is sent
		sta lastc
		lda #1
		jsr pack
		lda plen
		sta index
		ldx numx
		jsr putln
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
chatchk:
		lda #43		// &,43 chatchk: non-zero if the chat key was hit
		jmp usetbl1
carchk:
		lda #47		// &,47 carchk: 0 OK, 1 carrier lost, 2 time up
		jmp usetbl1
chatmode:
		lda #56		// &,56 chatmode
		jmp usetbl1

xchrout:
		sta $fe
		pha
		jsr xchrout1
		pla
		// fall through: keep track of where this leaves the cursor

// track the cursor (curx, cury: 1 = left/top, $ff = not known) after
// sending the character in A; A is kept
track:
		pha
		txa
		pha
		ldx curx
		cpx #$ff
		beq track9	// not known: only Home/Clear make it known
		cmp #13
		beq trackcr
		cmp #$8d	// shifted Return
		beq trackcr
		cmp #$11	// {down}
		beq trackdn
		cmp #$91	// {up}
		beq trackup
		cmp #$1d	// {right}
		beq trackrt
		cmp #$9d	// {left}
		beq tracklt
		cmp #$13	// {home}
		beq trackhm
		cmp #$93	// {clear}
		beq trackhm
		and #$7f
		cmp #32
		bcc track10	// another control code: doesn't move
trackrt:
		inc curx	// a character, or {right}
		jmp track10
tracklt:
		dec curx
		jmp track10
trackup:
		dec cury
		jmp track10
trackdn:
		inc cury
		jmp track10
trackcr:
		lda #1
		sta curx
		inc cury
		jmp track10
track9:
		cmp #$13	// {home}
		beq trackhm
		cmp #$93	// {clear}
		bne track10
trackhm:
		lda #1
		sta curx
		sta cury
track10:
		pla
		tax
		pla
		rts

revers:
		.byte 18+128, 18	// {rvrs off}, {rvrs on}

// put the cursor at crsrx, crsry (both from 1), the cheaper way: from where
// it is (curx, cury) with cursor keys, or from Home. Where it is isn't known
// ($ff): from Home.
crsrpos:
		lda curx
		cmp #$ff
		beq crsrpos4	// not known
		lda crsry	// |crsry-cury| + |crsrx-curx|: cursor keys from here
		sec
		sbc cury
		bcs crsrpos1
		eor #$ff
		adc #1
crsrpos1:
		sta vtemp
		lda crsrx
		sec
		sbc curx
		bcs crsrpos2
		eor #$ff
		adc #1
crsrpos2:
		clc
		adc vtemp
		sta vtemp
		lda crsry	// Home, then crsry-1 downs and crsrx-1 rights
		clc
		adc crsrx
		sec
		sbc #1
		cmp vtemp
		bcs crsrpos5	// from here is no dearer
crsrpos4:
		lda #$13	// {home}
		jsr xchrout	// (makes curx/cury 1,1)
crsrpos5:
		lda cury	// up or down to the line
		cmp crsry
		beq crsrpos7
		bcc crsrpos6
		lda #$91	// {up}
		jsr xchrout
		jmp crsrpos5
crsrpos6:
		lda #$11	// {down}
		jsr xchrout
		jmp crsrpos5
crsrpos7:
		lda curx	// then left or right to the column
		cmp crsrx
		beq crsrpos9
		bcc crsrpos8
		lda #$9d	// {left}
		jsr xchrout
		jmp crsrpos7
crsrpos8:
		lda #$1d	// {right}
		jsr xchrout
		jmp crsrpos7
crsrpos9:
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

// redraw the line from column A to its end (or its old end, so characters
// left over from before an edit are overwritten), packed; then go back to
// the current reverse/colour and to the cursor
redraw:
		sta rstart
		jsr lastcol
		cmp oldend
		bcs redraw1
		lda oldend
redraw1:
		sta pend
		lda pend
		cmp rstart
		bcc redraw2	// nothing to print from column A on
		ldx crsrx
		stx vtemp2
		lda rstart
		sta crsrx
		jsr crsrpos	// to column A
		lda vtemp2
		sta crsrx
		lda #$ff	// what's on screen here isn't known: send both
		sta lastr
		sta lastc
		lda rstart
		jsr pack
		jsr outbuf
redraw2:
		ldx crsrr
		lda revers,x
		jsr xchrout
		ldx crsrc
		lda colors,x
		jsr xchrout
		jmp crsrpos

// before an edit: remember where the line's text ends (redraw uses it)
markold:
		jsr lastcol
		sta oldend
		rts

// the last visible column of the line (1-39): a character other than a
// space, or a reverse space; 0 if the line is blank
lastcol:
		ldx #39
		ldy #3*39-1	// the character of column 39
lastcol1:
		lda (varbuf+1),y
		cmp #' '
		bne lastcol2
		dey
		dey
		lda (varbuf+1),y	// a space: its reverse byte
		cmp #$12	// {rvrs on}: a reverse space shows
		beq lastcol2
		dey		// the character of the column before
		dex
		bne lastcol1
lastcol2:
		txa
		rts

// pack columns A..pend into buffer, length in plen (at most 80 bytes):
// a reverse code only when it differs from lastr, a colour code only when
// it differs from lastc (and not for a space with reverse off, whose colour
// doesn't show), then the character. The caller sets lastr and lastc to
// what's already in effect, or $ff for "not known".
pack:
		sta pcol
		jsr colofs
		ldx #0
pack1:
		lda pend
		cmp pcol
		bcc pack9	// past the last column
		cpx #80-3
		bcs pack9	// full
		lda (varbuf+1),y	// reverse
		cmp lastr
		beq pack2
		sta lastr
		sta buffer,x
		inx
pack2:
		iny		// colour
		iny
		lda (varbuf+1),y	// (the character)
		dey
		cmp #' '
		bne pack3
		lda lastr
		cmp #$92	// a space with reverse off: its colour doesn't show
		beq pack4
pack3:
		lda (varbuf+1),y
		cmp lastc
		beq pack4
		sta lastc
		sta buffer,x
		inx
pack4:
		iny		// the character
		lda (varbuf+1),y
		sta buffer,x
		inx
		iny		// the next column
		inc pcol
		jmp pack1
pack9:
		stx plen
		rts

// send buffer (plen bytes) to the screen and modem
outbuf:
		ldx #0
outbuf1:
		cpx plen
		beq outbuf2
		stx outx
		lda buffer,x
		jsr xchrout
		ldx outx
		inx
		jmp outbuf1
outbuf2:
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
savecase:
		.byte 0		// the line editor's case flag, saved while editing
vtemp:
		.byte 0
vtemp2:
		.byte 0
pcol:
		.byte 0		// pack: the column being packed
pend:
		.byte 0		// pack: the last column to pack
plen:
		.byte 0		// pack: the length of the packed text in buffer
lastr:
		.byte 0		// pack: the reverse code in effect ($ff: not known)
lastc:
		.byte 0		// pack: the colour code in effect ($ff: not known)
outx:
		.byte 0		// outbuf: index into buffer
rstart:
		.byte 0		// redraw: the first column to redraw
oldend:
		.byte 0		// the line's last visible column before an edit
curx:
		.byte $ff	// where the cursor is (1 = left; $ff: not known)
cury:
		.byte $ff	// (1 = top)
