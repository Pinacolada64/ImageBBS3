.encoding "petscii_mixed"

#import "equat.s"

* = protostart "menu2.prg"

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
		.byte 0
w:
		.byte 0
r:
		.byte 0
c:
		.byte 0
a:
		.byte 0
x:
		.byte 0
y:
		.byte 0
px:
		.byte 0
py:
		.byte 0
sx:
		.byte 0
sy:
		.byte 0
cp:
		.byte 0

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
		.byte 0
key1:
		.byte 0
key2:
		.byte 0

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
cursm4:
		lda ($14),y
		cmp #255
		beq cursm9
		sta cp
cursm9:
		jmp cursm1

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
