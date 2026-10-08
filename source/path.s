.var version = "07/05/90 11:34p"

.encoding "petscii_mixed"

#import "equat.s"

* = $c000 "path.prg"

		jmp pathfind

		.byte 255
		.text version

src:
		.byte 0
dst:
		.byte 0

dir:
		.fill 32, 0
nod:
		.fill 32, 0

pathfind:
		txa
		beq loadfile //0
		dex
		beq srchpath //1
		dex
		beq findnode //2
		dex
		beq jshortct //3
		rts

jshortct:
		jmp shortcut

//load index file to end of proto
loadfile:
		ldx #var_a_string
		jsr usevar
		lda varbuf
		ldx varbuf+1
		ldy varbuf+2
		jsr setnam
		ldx #var_dv_integer
		jsr usevar
		lda #8
		ldx varbuf+1
		ldy #0
		jsr setlfs
		lda #0
		ldx #<last
		ldy #>last
		jsr loadf
		lda last
		sta varbuf+1
		lda #0
		sta varbuf
		ldx #var_a_integer
		jmp putvar

findnode:
		ldx #var_a_string
		jsr usevar
		jsr find
		sta varbuf+1
		lda #0
		sta varbuf
		ldx #var_a_integer
		jmp putvar

srchpath:
		ldx #var_b_integer
		jsr usevar
		lda varbuf+1
		sta dst
		bne srchpth1
		ldx #var_b_string
		jsr usevar
		jsr find
		sta dst
		tax
		beq srchpth3
srchpth1:
		ldx #var_a_integer
		jsr usevar
		lda varbuf+1
		sta src
		bne srchpth2
		ldx #var_a_string
		jsr usevar
		jsr find
		sta src
		tax
		beq srchpth3
srchpth2:
		jsr srch
srchpth3:
		stx varbuf
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2
		ldx #var_an_string
		jmp putvar

srch:
		ldx #0
		lda #3
		sta dir,x
srch01:
		lda src
		sta nod,x
		cmp dst
		beq srch07
srch02:
		inc dir,x
		lda dir,x
		cmp #8
		bcc srch03
		lda #4
		sta dir,x
		cpx #0
		beq srch11
srch03:
		jsr calc
		lda dir,x
		tay
		lda (20),y
		beq srch02
		cpx #0
		beq srch04
		cmp nod-1,x
		bne srch04
		dex
		lda nod,x
		sta src
		jmp srch02
srch04:
		sta src
		inx
		jsr calc
		ldy #4
srch05:
		lda (20),y
		cmp nod-1,x
		bne srch06
		tya
		sta dir,x
srch06:
		iny
		cpy #8
		bcc srch05
		jmp srch01
srch07:
		inx
		lda #0
		sta nod,x
		ldy #0
		ldx #0
srch08:
		lda #'/'
		jsr srch12
		lda nod,y
		beq srch10
		sta src
		tya
		pha
		jsr calc
		ldy #0
srch09:
		lda (20),y
		jsr srch12
		iny
		cpy #3
		bcc srch09
		pla
		tay
		iny
		jmp srch08
srch10:
		rts
srch11:
		ldx #0
		rts
srch12:
		sta buffer,x
		inx
		rts

find:
		lda #1
		sta src
find01:
		jsr calc
		ldy #0
find02:
		lda (20),y
		cmp (varbuf+1),y
		bne find03
		iny
		cpy #3
		bcc find02
		lda src
		rts
find03:
		lda src
		inc src
		cmp last
		bcc find01
		lda #0
		rts

calc:
		lda #0
		sta 21
		lda src
		sec
		sbc #1
		asl
		rol 21
		asl
		rol 21
		asl
		rol 21
		sec
		adc #<last
		sta 20
		lda 21
		adc #>last
		sta 21
		rts

shortcut:
		ldx #var_a_string
		jsr usevar
		ldy #2
shortcut_loop:
		lda (varbuf+1),y
		sta 105,y
		dey
		bpl shortcut_loop
		ldx #var_an_string
		jsr usevar
		ldy #0
		ldx #0
shortc0:
		cpy varbuf
		bcs shortc3
shortc0_loop:
		lda (varbuf+1),y
		cmp 105,x
		bne shortc1
		iny
		inx
		cpx #3
		bcc shortc0_loop
		dey
		dey
		dey
		tya
		clc
		adc varbuf+1
		sta varbuf+1
		lda #0
		adc varbuf+2
		sta varbuf+2
		sty varbuf+3
		lda varbuf
		sec
		sbc varbuf+3
		sta varbuf
		ldx #var_an_string
		jsr putvar
shortc1:
		cpx #0
		beq shortc2
		dey
		dex
		bne shortc1
shortc2:
		iny
		bne shortc0
shortc3:
		rts

usevar:
		lda #29
		jmp usetbl1
putvar:
		lda #30
		jmp usetbl1
last:
