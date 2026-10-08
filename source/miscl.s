stcount:
		.byte 0
stsize:
		.byte 0

lodstruc:
		jsr fnvar
		tya
		pha
		txa
		pha
		jsr evalfil
		pla
		tax
		pla
		tay
		lda #0
		jmp loadf

savstruc:
		jsr fnvar
		tya
		pha
		txa
		pha
		jsr evalint
		jsr evalfil
		pla
		sta $69
		adc $14
		tax
		pla
		sta $6a
		adc $15
		tay
		lda #$69
		jmp savef

struct:
		sty stcount
		cpx #0
		beq putstruc
		cpx #1
		beq getstruc
		cpx #2
		beq lodstruc
		cpx #3
		beq savstruc
		cpx #14
		beq putfloat
		cpx #15
		beq getfloat
		lda #68
		jmp usetbl1

putstruc:
		jsr fnvar1
		jsr evalstr
		sta stsize
		ldy #0
		tax
		beq puts2
puts1:
		lda ($22),y
		sta ($14),y
		iny
		cpy stcount
		bcs puts3
		dex
		bne puts1
puts2:
		lda #0
		sta ($14),y
		iny
		cpy stcount
		bcc puts2
puts3:
		rts

getstruc:
		jsr fnvar1
		jsr fnvar
		ldy #0
gets1:
		lda ($14),y
		beq gets2
		iny
		cpy stcount
		bcc gets1
gets2:
		sty stcount
		tya
		jsr makeroom
		ldy #0
gets3:
		cpy stcount
		beq gets4
		lda ($14),y
		sta ($62),y
		iny
		bne gets3
gets4:
		ldy #4
gets5:
		lda $61,y
		sta ($47),y
		dey
		bpl gets5
		rts

putfloat:
		jsr fnvar1
		jsr fnvar
		ldy #4
putf1:
		lda ($47),y
		sta ($14),y
		dey
		bpl putf1
		rts

getfloat:
		jsr fnvar1
		jsr fnvar
		ldy #4
getf1:
		lda ($14),y
		sta ($47),y
		dey
		bpl getf1
		rts

cursposn:
		sty cursp0+1
		stx cursp2+1
		jsr cursmode
		beq cursp4
		lda #cursor_home
		jsr xchrout
cursp0:
		ldx #0
		beq cursp2
cursp1:
		lda #cursor_down
		jsr xchrout
		dex
		bne cursp1
cursp2:
		ldx #0
		beq cursp4
cursp3:
		lda #cursor_right
		jsr xchrout
		dex
		bne cursp3
cursp4:
		rts

cursmode:
		ldx #16
		jsr chkflag //asc
		bne cursmod1
		lda #1
		rts
cursmod1:
		ldx #18
		jsr chkflag //ans
		beq cursmod2
		lda #2
		rts
cursmod2:
		lda #0
		rts

calcgoto:
		txa
		pha
		ldx #var_a_integer
		jsr usevar
		ldx varbuf+1
		ldy varbuf
		pla
		bne calcgot1
		jmp mlgoto
calcgot1:
		jmp mlgosub

ecschk:
		stx stsize
		sty stcount
		jsr evalint
		sty ecsc5+1
		stx ecsc6+1
		jsr fnvar
		stx ecsc3+1
		sty ecsc4+1
		jsr evalstr
		sta index
		ldy #0
ecsc1:
		lda #0
		cpy index
		bcs ecsc2
		lda ($22),y
ecsc2:
		sta buf2,y
		iny
		cpy #8
		bcc ecsc1
		lda index
		beq ecsquit
		ldy #0
ecsc3:
		lda #0
		sta varbuf+3
ecsc4:
		lda #0
		sta varbuf+4
		lda #0
		sta varbuf+0
		lda #1
		sta varbuf+1
ecsscan:
		ldy #2
		lda (varbuf+3),y
ecsc5:
		and #0
		bne ecsscan1
		ldy #3
		lda (varbuf+3),y
ecsc6:
		and #0
		beq ecsnext
ecsscan1:
		ldy #6
		ldx #0
ecsscan2:
		lda (varbuf+3),y
		iny
		cmp buf2,x
		bne ecsnext
		cpy stsize
		bcs ecsdone
		inx
		cpx #8
		bcc ecsscan2
		jmp ecsdone

ecsnext:
		lda varbuf+3
		clc
		adc stsize
		sta varbuf+3
		lda varbuf+4
		adc #0
		sta varbuf+4
		inc varbuf+1
		dec stcount
		bne ecsscan
ecsquit:
		lda #0
		sta varbuf
		sta varbuf+1
ecsdone:
		ldx #var_a_integer
		jmp putvar

arbit:
		sty lu_load+1
		lda $ffd2
		cmp #$20
		bne arbit1
		dex
		beq lock
		dex
		beq unlock
arbit1:
		rts

lock:
		clc
		jsr block
		bpl idle
		cmp port_load+1
		beq lock1
		ldy #$cc // reverse uppercase L
		sty tdisp+31
		jsr tdelay
		bne lock
idle:
		ldx #0
		lda port_load+1
lock1:
		inx
		sec
		jsr block
		jsr tdelay
		clc
		jsr block
port_load:
		cmp #0
		bne lock
		ldy #$a0
		sty tdisp+31
		rts

unlock:
		clc
		jsr block
		bpl unlock0
		cmp port_load+1
		bne unlock0
		dex
		bne unlock1
		lda #0
unlock1:
		sec
		jmp block
unlock0:
		rts

block:
		jsr ltk_bnkout
		php
		sta ltk_redbuf
		stx ltk_redbuf+1
lu_load:
// changed by self-modifying code
		lda #0
		sec
blkl_load:
// changed by self-modifying code
		adc #0
		tax
		lda #0
blkh_load:
// changed by self-modifying code
		adc #0
		tay
		lda #10
		plp
		jsr ltk_driver
		.word ltk_redbuf
		.byte 1
		ldx ltk_redbuf+1
		lda ltk_redbuf
		jsr ltk_bankin
		cli
		rts

tdelay:
		lda d1icr
		lda #%00000010
dloop:
		bit d1icr
		beq dloop
		rts

