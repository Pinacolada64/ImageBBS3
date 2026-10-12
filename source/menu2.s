.encoding "petscii_mixed"

#import "equat.s"

* = protostart "menu2.prg"

// menu2: cursor-driven ("graphic") menus, loaded at $c000 and called with
// &,16. Used by i.IM, i.GF, i.UU, i.DE, i.SM and i_lo.on.
//
// Every call starts &,16,f,size,m%(...):
//   f       function (0-3, below), passed in X
//   size    bytes per menu item: 2*(first dim+1), e.g. 34 for dim m%(16,n),
//           42 for m%(20,n), 46 for m%(22,n). Passed in Y.
//   m%()    integer array of menu items, one per record; functions 0 and 1
//           name the item to fill, functions 2 and 3 the first item
//
// One item (byte offsets; integers are high byte first):
//   0-1    m%(0,i)    screen column, row (set by function 2)
//   2-5    m%(1-2,i)  item to go to on up, down, right, left (function 2)
//   6-7    m%(3,i)    hotkey prefix (0 for none, e.g. "/"), hotkey;
//                     the key is chr$(m%(3,i) and 255)
//   8-9    m%(4,i)    value: 0, or the record number (function 1)
//   10-13  m%(5-6,i)  up to 4 characters shown before the hotkey (0 = end)
//   14-    m%(7-,i)   title, up to size-14 characters (0 = end)
//
// &,16,0,size,m%(.,i),key$,prefix$,title$
//   add one item. key$: one key ("A") or a prefix and a key ("/B").
//   prefix$: up to 4 characters, e.g. "Op " in i.GF.
//
// &,16,1,size,m%(.,i),key$,types$,recsize,flags,mask,type,title,titlelen,
//        count,most,value
//   add items from a struct array (records of recsize bytes; flags, type
//   and title name fields of its first record). Of the next count records,
//   those whose flags have any bit of mask set become items, up to most of
//   them. The first gets hotkey key$, the next key$+1 and so on; the prefix
//   is 4 characters of types$ starting at (type and 255)*4; the title is
//   titlelen bytes of the title field; the item's value is value plus the
//   record's position in the scan.
//   Returns a% = records checked, b% = items added.
//   i.GF: &,16,1,42,q%(0,n),"1",ct$,80,s%(0,1),1,s%(2,1),s%(13,1),28,rn,9,1
//
// &,16,2,size,m%(.,first),n,width,columns,rows,x,y,start
//   draw n items in a blue frame, filling each column top to bottom, then
//   let the user choose (as function 3). The frame is printed from the
//   cursor's current place: x,y is where the cursor goes on the first item
//   (its hotkey), and must match what is printed. Each column is width+2
//   characters wide. start = item the cursor starts on (0 = first).
//   i.IM: &,16,2,34,m%(.,1),n,17,2,n/2+.5,2,6,.  (2 columns, under a
//   4-line header)
//
// &,16,3,size,m%(.,first),n,start
//   choose from a menu that is already on the screen.
//   Keys: cursor keys or ANSI ESC [ A-D move (wrapping around); Return
//   chooses the item under the cursor; a hotkey chooses its item at once
//   (a prefixed one only right after its prefix; of several single-key
//   items with the same key, the last wins).
//   Returns a% = the item chosen, 0 for the first (callers use lm=a%+1).

ml:
		stx ml1+1
		sty stsize
		lda #r6510_normal
		sta r6510
		jsr fnvarx1
		stx menubase
		sty menubase+1
ml1:
		ldx #0
		bne ml2
		jmp addstr
ml2:
		dex
		bne ml3
		jmp addarr
ml3:
		dex
		bne ml4
		jmp usemenu
ml4:
		dex
		bne ml5
		jmp cursmenu
ml5:
		rts

fnvarx:
		jsr chkcom
		jsr $b08b
		ldx $47
		ldy $48
		rts
fnvarx1:
		jsr fnvarx
		stx $14
		sty $15
		rts

evalbytx:
		jsr chkcom
		jsr $0079
		jmp $b79e

evalstrx:
		jsr chkcom
		jsr $ad9e
		jsr $b6a3
		cmp #0
		rts

getword:
		jsr $aefd
		jsr $ad8a
		jsr $b7f7
		ldx $14
		ldy $15
		rts

putvar:
		lda #30
		jmp usetbl1
xchrout0:
		cmp # 32
		bcc xchrout2
		cmp #128
		bcc xchrout3
		cmp #133
		bcc xchrout2
		cmp #140
		bcc xchrout3
		cmp #160
		bcc xchrout2
xchrout3:
		inx
xchrout:
		sta $fe
xchrout1:
		lda #24
		jmp usetbl1
xchrout2:
		rts
xgetin:
		lda #23
		jmp usetbl1

stsize:
		.byte 0
stcount:
		.byte 0

// function 0: fill item ($14) from key$, prefix$ ("type$") and title$
// note: an empty key$ isn't checked for, so its bytes are whatever
// ($22) points at
addstr:
		jsr evalstrx //key$
		ldx #0
		ldy #0
		cmp #1
		beq addstr1
		lda ($22),y
		tax
		iny
addstr1:
		lda ($22),y
		ldy #7
		sta ($14),y
		dey
		txa
		sta ($14),y
		ldy #8
		lda #0
		sta ($14),y
		iny
		sta ($14),y
		jsr evalstrx //type$
		sta stcount
		stx addstr2+1
		sty addstr2+2
		ldy #10
		ldx #0
		cmp #0
		beq addstr3
addstr2:
		lda $ffff,x
		inx
		sta ($14),y
		iny
		cpx #4
		bcs addstr4
		cpx stcount
		bcc addstr2
addstr3:
		lda #0
		sta ($14),y
		iny
		inx
		cpx #4
		bcc addstr3
addstr4:
		jsr evalstrx //title$
		sta stcount
		stx addstr5+1
		sty addstr5+2
		ldy #14
		ldx #0
		cmp #0
		beq addstr6
addstr5:
		lda $ffff,x
		inx
		sta ($14),y
		iny
		cpy stsize
		bcs addstr7
		cpx stcount
		bcc addstr5
addstr6:
		lda #0
		sta ($14),y
		iny
		cpy stsize
		bcc addstr6
addstr7:
		rts

keyvalue:
		.byte 0
itemsiz:
		.byte 0
bitvalue:
		.word 0
titlsize:
		.byte 0
maxcount:
		.byte 0
chkcount:
		.byte 0
addcount:
		.byte 0
maxadd:
		.byte 0
arrvalue:
		.word 0

// function 1: add items from a struct array (see the top of the file)
// notes: types$ isn't checked for length; the title copy stops at titlelen
// or when the character count reaches size (not the end of the item), so a
// titlelen over size-14 runs into the next item; a shorter title leaves
// whatever was in the rest of the item
addarr:
		lda $14
		pha
		lda $15
		pha
		jsr evalstrx //key$
		ldy #0
		lda ($22),y
		sta keyvalue
		jsr evalstrx //type$
		stx addarr6+1
		sty addarr6+2
		jsr evalbytx
		stx itemsiz
		jsr fnvarx //flags
		stx addarr2+1
		sty addarr2+2
		jsr getword
		stx bitvalue+1
		sty bitvalue
		jsr fnvarx //type
		stx addarr5+1
		sty addarr5+2
		jsr fnvarx //title
		stx addarr7+1
		sty addarr7+2
		jsr evalbytx
		stx titlsize
		jsr evalbytx
		stx maxcount
		jsr evalbytx
		stx maxadd
		jsr getword
		stx arrvalue
		sty arrvalue+1
		pla
		sta $15
		pla
		sta $14
		lda #0
		sta addcount
		sta chkcount
		lda maxcount
		bne addarr1
		jmp addarrd
addarr1:
		ldx #1
addarr2:
		lda $ffff,x
		and bitvalue,x
		bne addarr4
		dex
		bpl addarr2
		jmp addarr9
addarr4:
		lda #0
		ldy #6
		sta ($14),y
		lda keyvalue
		iny
		sta ($14),y
		lda arrvalue+1
		iny
		sta ($14),y
		lda arrvalue
		iny
		sta ($14),y
		ldx #1
addarr5:
		lda $ffff,x
		asl
		asl
		tax
		ldy #10
addarr6:
		lda $ffff,x
		sta ($14),y
		iny
		inx
		cpy #14
		bcc addarr6
		ldx #0
addarr7:
		lda $ffff,x
		sta ($14),y
		iny
		inx
		cpx titlsize
		bcs addarr8
		cpx stsize
		bcc addarr7
addarr8:
		inc keyvalue
		inc addcount
		clc
		lda $14
		adc stsize
		sta $14
		bcc addarr9
		inc $15
addarr9:
		clc
		lda addarr2+1
		adc itemsiz
		sta addarr2+1
		bcc addarra
		inc addarr2+2
addarra:
		clc
		lda addarr5+1
		adc itemsiz
		sta addarr5+1
		bcc addarrb
		inc addarr5+2
addarrb:
		clc
		lda addarr7+1
		adc itemsiz
		sta addarr7+1
		bcc addarrc
		inc addarr7+2
addarrc:
		inc arrvalue+1
		bne addarre
		inc arrvalue
addarre:
		inc chkcount
		lda chkcount
		cmp maxcount
		bcs addarrd
		lda addcount
		cmp maxadd
		bcs addarrd
		jmp addarr1
addarrd:
		lda #0
		sta varbuf
		lda chkcount
		sta varbuf+1
		ldx #var_a_integer
		jsr putvar
		lda #0
		sta varbuf
		lda addcount
		sta varbuf+1
		ldx #var_b_integer
		jmp putvar

// $14/$15 = address of item X
calcbase:
		lda menubase
		ldy menubase+1
		cpx #0
		beq calcb3
calcb1:
		clc
		adc stsize
		bcc calcb2
		iny
calcb2:
		dex
		bne calcb1
calcb3:
		sta $14
		sty $15
		rts

// store in the item the item to go to for each direction (Y = offset,
// 2-5), wrapping at the edges. a = this item, x/y = its column/row,
// items run down each column (r per column)
linkleft:
		lda a
		sec
		sbc r
		ldx x
		bne putlink
		ldx c
linkl1:
		clc
		adc r
		dex
		bne linkl1
		ldx y
		bne linku1
		lda n
		sec
		sbc #1
		jmp putlink
linkrigh:
		lda a
		clc
		adc r
		ldx x
		inx
		cpx c
		bne putlink
		ldx c
linkr1:
		sec
		sbc r
		dex
		bne linkr1
		ldx y
		inx
		cpx r
		bne linkd1
		lda #0
		beq putlink
linkdown:
		lda a
linkd1:
		clc
		adc #1
		cmp n
		bne putlink
		lda #0
		beq putlink
linkup:
		lda a
linku1:
		sec
		sbc #1
		cmp #255
		bne putlink
		lda n
		sec
		sbc #1
putlink:
		cmp n
		bcc putl1
		lda #0
putl1:
		sta ($14),y
		iny
		rts

menubase:
		.word 0
n:
		.byte 0 // number of items
w:
		.byte 0 // column width
r:
		.byte 0 // rows
c:
		.byte 0 // columns
a:
		.byte 0 // item being drawn
x:
		.byte 0 // its column
y:
		.byte 0 // its row
px:
		.byte 0 // its screen column
py:
		.byte 0 // its screen row
sx:
		.byte 0 // screen column of the first item
sy:
		.byte 0 // screen row of the first item
cp:
		.byte 0 // item under the cursor

// function 2: draw the menu, fill in each item's position and links,
// then fall into the cursor loop (cursm0)
usemenu:
		jsr evalbytx
		stx n
		jsr evalbytx
		stx w
		jsr evalbytx
		stx c
		jsr evalbytx
		stx r
		jsr evalbytx
		stx sx
		jsr evalbytx
		stx sy
		jsr evalbytx
		stx cp
		lda #0
		sta x
usemh:
		jsr putback
		inc x
		lda x
		cmp c
		bcc usemh
		jsr putend
		lda #0
		sta x
usem0:
		jsr puttop
		inc x
		lda x
		cmp c
		bcc usem0
		jsr putend
		lda #0
		sta y
usem1:
		lda y
		sta a
		clc
		adc sy
		sta py
		lda sx
		sta px
		lda #0
		sta x
usem2:
		lda a
		cmp n
		bcc usem3
		jsr putblank
		jmp usemb
usem3:
		ldx a
		jsr calcbase
		ldy #0
		lda px
		sta ($14),y
		iny
		lda py
		sta ($14),y
		iny
		jsr linkup
		jsr linkdown
		jsr linkrigh
		jsr linkleft
		jsr putitem
usemb:
		lda a
		clc
		adc r
		sta a
		lda px
		clc
		adc w
		clc
		adc #2
		sta px
		inc x
		lda x
		cmp c
		beq usemc
		jmp usem2
usemc:
		jsr putend
		inc py
		inc y
		lda y
		cmp r
		beq usemd
		jmp usem1
usemd:
		lda #0
		sta x
useme:
		jsr putblank
		inc x
		lda x
		cmp c
		bcc useme
		jsr putend
		lda #0
		sta x
usemf:
		jsr putlast
		inc x
		lda x
		cmp c
		bcc usemf
		jsr putend
		lda #0
		sta x
usemg:
		jsr putback
		inc x
		lda x
		cmp c
		bcc usemg
		jsr putend
		jmp cursm0

putend:
		lda #reverse_on
		jsr xchrout
		lda #' '
		jsr xchrout
		lda #13
		jmp xchrout

put0:
		lda #cursor_blue
		jsr xchrout
		lda #reverse_on
		jsr xchrout
		lda #' '
		jsr xchrout
		lda #cursor_cyan
		jsr xchrout
		lda #' '
		jmp xchrout

puttop:
		jsr put0
		ldx #1
putt1:
		lda #' '
		jsr xchrout
		inx
		cpx w
		bne putt1
put2:
		lda #cursor_blue
		jsr xchrout
		lda #' '
		jmp xchrout

putback:
		lda #cursor_blue
		jsr xchrout
		lda #reverse_on
		jsr xchrout
		lda #' '
		jsr xchrout
		lda #' '
		jsr xchrout
		ldx #0
		beq putx1

putlast:
		lda #cursor_blue
		jsr xchrout
		lda #reverse_on
		jsr xchrout
		lda #' '
		jsr xchrout
		lda #' '
		jsr xchrout
		lda #reverse_off
		jsr xchrout
		ldx #0
putx1:
		lda #' '
		jsr xchrout
		inx
		cpx w
		bne putx1
		rts

putblank:
		jsr put0
		ldx #1
putb1:
		lda #' '
		jsr xchrout
		inx
		cpx w
		bne putb1
put1:
		lda #cursor_blue
		jsr xchrout
		lda #reverse_off
		jsr xchrout
		lda #' '
		jmp xchrout

// print an item: prefix text, hotkey (white), title (cyan), padded to w
putitem:
		jsr put0
		ldx #1
		ldy #10
puti3:
		lda ($14),y
		beq puti4
		jsr xchrout0
		iny
		cpy #14
		bcc puti3
puti4:
		lda #cursor_white
		jsr xchrout
		ldy #6
		lda ($14),y
		beq puti5
		jsr xchrout
		inx
puti5:
		ldy #7
		lda ($14),y
		jsr xchrout0
		lda #cursor_cyan
		jsr xchrout
		lda #' '
		jsr xchrout0
		ldy #14
puti7:
		lda ($14),y
		beq puti8
		jsr xchrout0
		iny
		cpy stsize
		bcs puti8
		cpx w
		bcc puti7
puti8:
		cpx w
		bcs puti9
		lda #' '
		jsr xchrout
		inx
		bne puti8
puti9:
		jmp put1

findflag:
		.byte 0 // a single-key hotkey matched
key1:
		.byte 0 // last key typed
key2:
		.byte 0 // the key before it (ESC [ sequence or hotkey prefix)

// function 3: let the user choose; a% = item chosen
cursmenu:
		jsr evalbytx
		stx n
		jsr evalbytx
		stx cp
cursm0:
		lda #1
		sta case
		lda #0
		sta key1
		sta key2
cursm1:
		ldx cp
		jsr curscalc
cursm2:
		ldx cp
		jsr calcbase
		jsr xgetin
		ldx key1
		stx key2
		sta key1
		cmp #13
		beq cursm3
		cpx #'['
		bne cursm5
		ldy #2
		cmp #'A'
		beq cursm4
		iny
		cmp #'B'
		beq cursm4
		iny
		cmp #'C'
		beq cursm4
		iny
		cmp #'D'
		beq cursm4
cursm5:
		ldy #2
		cmp #cursor_up
		beq cursm4
		iny
		cmp #cursor_down
		beq cursm4
		iny
		cmp #cursor_right
		beq cursm4
		iny
		cmp #cursor_left
		beq cursm4
// not a cursor key: look for an item with this hotkey
		ldx #0
		jsr calcbase
		ldx #0
		stx findflag
cursm7:
		ldy #7
		lda ($14),y
		cmp key1
		bne cursm7c
cursm7a:
		dey
		lda ($14),y
		beq cursm7b
		cmp key2
		bne cursm7c
		stx cp
		jmp cursm8
cursm7b:
		stx cp
		inc findflag
cursm7c:
		clc
		lda $14
		adc stsize
		sta $14
		lda $15
		adc #0
		sta $15
		inx
		cpx n
		bcc cursm7
		lda findflag
		bne cursm8
		jmp cursm2
cursm8:
		ldx cp
		jsr curscalc
cursm3:
		lda cp
		sta varbuf+1
		lda #0
		sta varbuf
		ldx #var_a_integer
		jmp putvar
// cursor key: move to the item linked at offset Y (255 = stay)
cursm4:
		lda ($14),y
		cmp #255
		beq cursm9
		sta cp
cursm9:
		jmp cursm1

// put the cursor on item X (&,70 with its column and row)
curscalc:
		jsr calcbase
		ldy #0
		lda ($14),y
		tax
		iny
		lda ($14),y
		tay

cursposn:
		lda #70
		jmp usetbl1
