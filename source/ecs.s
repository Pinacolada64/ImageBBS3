.pseudopc protostart {
.namespace ecsml {

.label a=0
.label ecsdefs_size = $a00

//common parts
// 0-1..flag
// ..... bit 32768
// ..... bit 16384
// ..... bit .8192
// ..... bit .4096
// ..... bit .2048
// ..... bit .1024
// ..... bit ..512
// ..... bit ..256
// ..... bit ..128
// ..... bit ...64
// ..... bit ...32
// ..... bit ...16
// ..... bit ....8
// ..... bit ....4
// ..... bit ....2
// ..... bit ....1
// 1-2..access
// 3-4..credits

//long format
// 0......flag (same as short)
// 1-2....access
// 3-9....command (7 chars)
// 10-23..file (14 chars)
// 24-31..password (7 chars)
// 32.....credits

ecs:
		cpx #0
		bne ecs1
		jmp ecschk
ecs1:
		dex
		bne ecs2
		jmp ecsgoto
ecs2:
		dex
		bne ecs3
		jmp ecsget
ecs3:
		dex
		bne ecs4
		jmp ecsput
ecs4:
		dex
		bne ecs5
		jmp ecsload
ecs5:
		dex
		bne ecs6
		jmp ecssave
ecs6:
		rts

ecsgoto:
		ldx #var_a_integer
		jsr usevar
		lda varbuf+1
		sta $14
		lda varbuf
		sta $15
		lda r6510
		pha
		lda #r6510_normal
		sta r6510
		jsr $a8a3
		pla
		sta r6510
		rts

ecschk:
		ldx #var_an_string
		jsr usevar
		ldy varbuf
		sty index
ecsc2:
		lda (varbuf+1),y
		sta buffer,y
		dey
		bpl ecsc2
		ldx #var_ac_integer
		jsr usevar
		ldx varbuf+1
		sec
		lda #0
		sta acc
		sta acc+1
ecsc3:
		rol acc
		rol acc+1
		dex
		bpl ecsc3
		ldx #var_a_integer
		jsr usevar
		lda varbuf+1
		sta zzf
		lda index
		beq ecsquit
		ldy #0
		lda #<ecsdefs
		sta varbuf+3
		lda #>ecsdefs
		sta varbuf+4
ecsscan:
		lda (varbuf+3),y
		tax
		and #64
		beq ecsnext
		txa
		and #3
		beq ecsscan1
		and zzf
		beq ecsnext
ecsscan1:
		ldy #1
		lda (varbuf+3),y
		and acc
		bne ecsscan2
		ldy #2
		lda (varbuf+3),y
		and acc+1
		beq ecsnext
ecsscan2:
		ldy #0
		lda (varbuf+3),y
		pha
		and #8
		bne ecsscan3
		jsr ecslong
		jmp ecsscan4
ecsscan3:
		jsr ecsshort
ecsscan4:
		pla
		bcc ecsnext
// got it!
		bmi ecsscan5
		lda #5
		bne ecsquit
ecsscan5:
		lsr
		lsr
		lsr
		lsr
		and #3
		clc
		adc #1
ecsquit:
		sta varbuf+1
		lda #0
		sta varbuf
		sta varbuf+2
		sta varbuf+3
		sta varbuf+4
		ldx #var_a_integer
		jmp putvar

ecsnext:
		ldy #0
		lda (varbuf+3),y
		and #$c0
		beq ecsquit
		ldy #0
		lda (varbuf+3),y
		ldx #8
		and #8
		bne ecsnext1
		ldx #32
ecsnext1:
		clc
		txa
		adc varbuf+3
		sta varbuf+3
		tya
		adc varbuf+4
		sta varbuf+4
		cmp #>(ecs+ecsdefs_size)
		bne ecsscan
		lda #0
		beq ecsquit

acc:
		.word 0
zzf:
		.byte 0

// check long command, cc=not equal
ecslong:
		ldx #0
		ldy #3
ecslong1:
		lda (varbuf+3),y
		beq ecslong2
		cmp buffer,x
		bne ecslong3
		iny
		inx
		cpx #7
		bne ecslong1
ecslong2:
		cpx index
		beq ecslong4
//nope
ecslong3:
		clc
		rts
//yup
ecslong4:
		ldy #24
		lda (varbuf+3),y
		beq ecslong5
//do password later
ecslong5:
		ldy #10
		ldx #0
ecslong6:
		lda (varbuf+3),y
		beq ecslong7
		sta buffer,x
		iny
		inx
		cpx #14
		bcc ecslong6
ecslong7:
		stx index
		stx varbuf
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2
		ldx #var_b_string
		jsr putvar
		ldy #24
		ldx #0
ecslong8:
		lda (varbuf+3),y
		beq ecslong9
		sta buf2,x
		iny
		inx
		cpx #8
		bcc ecslong8
ecslong9:
		stx index
		stx varbuf
		lda #<buf2
		sta varbuf+1
		lda #>buf2
		sta varbuf+2
		ldx #var_a_string
		jsr putvar
		ldy #31
		lda (varbuf+3),y
		sta varbuf+1
		lda #0
		sta varbuf
		ldx #var_b_integer
		jsr putvar
		sec
		rts

// check short command,cc=not equal
ecsshort:
		ldy #0
		lda (varbuf+3),y
		and #4
		beq ecsshrt1
		lda index
		cmp #2
		bcs ecsshrt2
ecsshrt1:
		lda index
		cmp #2
		bne ecsshrt3
ecsshrt2:
		ldy #3
		lda (varbuf+3),y
		cmp buffer
		bne ecsshrt3
		ldy #4
		lda (varbuf+3),y
		cmp buffer+1
		beq ecsshrt4
//nope
ecsshrt3:
		clc
		rts
//yup
ecsshrt4:
		ldy #5
		lda (varbuf+3),y
		sta buffer
		ldy #6
		lda (varbuf+3),y
		sta buffer+1
		ldx #2
		stx index
		stx varbuf
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2
		ldx #var_b_string
		jsr putvar
		ldy #7
		lda (varbuf+3),y
		sta varbuf+1
		lda #0
		sta varbuf
		ldx #var_b_integer
		jsr putvar
		ldx #var_a_string
		jsr usevar
		lda #0
		sta varbuf
		lda #<buf2
		sta varbuf+1
		lda #>buf2
		sta varbuf+2
		ldx #var_a_string
		jsr putvar
		sec
		rts

ecsget:
		ldx #0
		stx $6b
		lda #<ecsdefs
		sta $69
		lda #>ecsdefs
		sta $6a
ecsg1:
		inc $6b
		jsr ecsgetln
		lda $6a
		cmp #>(ecs+ecsdefs_size)
		bcs ecsg2
		ldy #0
		lda ($69),y
		bne ecsg1
ecsg2:
		lda $6b
		sta varbuf+1
		lda #0
		sta varbuf
		sta varbuf+2
		sta varbuf+3
		sta varbuf+4
		ldx #var_a_integer
		jmp putvar

ecsput:
		sty $6c
		lda #0
		sta $6b
		lda #<ecsdefs
		sta $69
		lda #>ecsdefs
		sta $6a
ecsp1:
		inc $6b
		jsr ecsputln
		lda $6a
		cmp #>(ecs+ecsdefs_size)
		bcs ecsp2
		lda $6b
		cmp $6c
		bne ecsp1
ecsp2:
		rts

ecsgetln:
		ldy #31
ecsgl1:
		lda ($69),y
		sta buffer,y
		dey
		bpl ecsgl1
		ldy #8
		lda buffer
		and #8
		bne ecsgl2
		ldy #32
ecsgl2:
		sty index
		tya
		clc
		adc $69
		sta $69
		lda #0
		adc $6a
		sta $6a
		ldx $6b
		jmp putln

ecsputln:
		ldx $6b
		jsr getln
		ldy #7
		lda buffer
		and #8
		bne ecspl1
		ldy #31
ecspl1:
		sty index
ecspl2:
		lda buffer,y
		sta ($69),y
		dey
		bpl ecspl2
		sec
		lda index
		adc $69
		sta $69
		lda #0
		adc $6a
		sta $6a
		rts

getln:
		lda #35
		jmp usetbl1
putln:
		lda #36
		jmp usetbl1
usevar:
		lda #29
		jmp usetbl1
putvar:
		lda #30
		jmp usetbl1

ecsload:
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
		ldx #<ecsdefs
		ldy #>ecsdefs
		jmp loadf

ecssave:
// TODO combine with common code from ecsload
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
		lda #<ecsdefs
		ldx #>ecsdefs
		sta varbuf
		stx varbuf+1
		ldx #<(ecs+ecsdefs_size)
		ldy #>(ecs+ecsdefs_size)
		lda #varbuf
		jmp savef

.align 32

ecsdefs:

}
}
