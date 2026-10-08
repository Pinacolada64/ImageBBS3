//*
//* string output routines *
//*

//* output string
outstr:
		lda #0
		sta $96
		lda varbuf
		sta len1
		lda varbuf+1
		sta $71
		lda varbuf+2
		sta $72

// skip next check if user timed out

		jsr gettsr
		beq outstr0

		lda someflag
		bne outstr5
outstr0:

// handle "skip lines" counter

		lda mjump
		beq outstr1
		dec mjump
		beq outstr1
		bne outstr5
outstr1:
		jsr zero
		ldx #var_rc_float
		jsr putvar
		ldx #var_lp_float
		jsr usevar
		ldx #0
		lda varbuf
		beq outstr2
		inx
outstr2:
		stx wrapflg
		lda #0
		sta lastout
		jsr outstr7
		jsr zero
		lda chat
		sta varbuf+1
		ldx #var_kp_integer
		jsr putvar
		lda chat
		beq outstr3
		jsr minusone
		ldx #var_rc_float
		jsr putvar
		jsr zero
		ldx #var_sh_float
		jsr putvar
		lda chat
		cmp #'/'
		bne outstr3
		lda #$86 // part of float value
		sta varbuf
		lda #$3c // part of float value
		sta varbuf+1
		ldx #var_sh_float
		jsr putvar
outstr3:
		lda wrapflg
		beq outstr6
		lda lastout
		cmp #32
		beq outstr5
outstr4:
		lda #13
		sta $fe
		jsr output
outstr5:
		jsr zero
		ldx #var_lp_float
		jsr putvar
outstr6:
		rts

lastout:
		.byte 0

outstr7:
		jsr setoutmd
		lda #0
		sta chat
		jsr carchk
		cmp #1
		bne outstr8
		lda #'/'
		sta chat
		rts
outstr8:
		lda len1
		beq outstr11
		ldy $96
outstr9:
		sty $96
		lda ($71),y
		sta $fe
		sta lastout
		jsr domci
		jsr moreprmt
		lda chat
		beq outstr10
		lda wrapflg
		beq outstr10
		lda readmode
		bne outstr10
		rts
outstr10:
		ldy $96
		iny
		cpy len1
		bcc outstr9
outstr11:
		rts

convtbl:
		.byte <convan0,<convstr
		.byte <convstr,<convstr
		.byte <convstr,<newdate
		.byte <strscan
convtbh:
		.byte >convan0,>convstr
		.byte >convstr,>convstr
		.byte >convstr,>newdate
		.byte >strscan

// manipluate an$
convan:
		cpx #7
		bcs cjmp
		lda convtbl,x
		sta cjmp+1
		lda convtbh,x
		sta cjmp+2
cjmp:
		jmp convan0

convan0:
		ldx #var_an_string
		jsr usevar
		ldy #10
convan1:
		lda (varbuf+1),y
		sta datebuf,y
		dey
		bpl convan1
		jsr convert
// copy "Www Mmm dd, yyyy hh:mm A" (24 bytes): includes weekday,
// omits trailing "M" since callers append it themselves
		lda #24
		jsr makeroom
		ldy #23
convan2:
		lda date1,y
		sta (varbuf+1),y
		dey
		bpl convan2
		ldx #var_an_string
		jmp putvar

ctrlchk0:
		pha
		and #$7f
		cmp #32
		pla
		rts

// carry clear if control
ctrlchk:
		pha
		lda editor
		and #1
		beq ctrlch0
		pla
ctrlchk1:
		jsr colorchk
		bcc ctrlch2
		jsr ctrlchk2
		bcc ctrlch2
		pha
ctrlch0:
		pla
		cmp #32
		bcc ctrlch1
		cmp #128
		bcc ctrlch2
		cmp #160
		bcs ctrlch2
		cmp #133
		bcc ctrlch1
		cmp #141
		bcs ctrlch1
ctrlch2:
		sec
		rts
ctrlch1:
		clc
		rts

// carry clear if color chr
colorchk:
		sty cytmp
		ldy #15
colrch0:
		cmp colors,y
		beq colrch1
		dey
		bne colrch0
		ldy cytmp
		sec
		rts
colrch1:
		ldy cytmp
		clc
		rts

ctrlchk2:
		cmp #reverse_on
		beq ctrlch2a
		cmp #reverse_off
		beq ctrlch2a
		cmp #cursor_down
		beq ctrlch2a
		cmp #cursor_up
		beq ctrlch2a
		cmp #cursor_right
		beq ctrlch2a
		cmp #cursor_left
		beq ctrlch2a
		sec
		rts
ctrlch2a:
		clc
		rts

more0:
		rts
moreprmt:
		lda local
		bne more0
		lda usrlinm
		beq more0
		lda usrlin
		cmp usrlinm
		bcc more0
		lda flag_mor_addr
		and #flag_mor_l_mask
		beq more0
		lda #0
		sta usrlin
		ldx #4
moreprmt_loop1:
		lda varbuf,x
		pha
		dex
		bpl moreprmt_loop1
		ldx #var_mp_string
		jsr usevar
		ldy #0
moreprmt_loop2:
		lda (varbuf+1),y
		jsr xchrout
		iny
		cpy varbuf
		bcc moreprmt_loop2
		lda #1
		jsr comy0
		bne more1
		lda #'/'
		sta chat
more1:
		ldy #0
moreprmt_loop3:
		lda #20
		jsr xchrout
		iny
		cpy varbuf
		bcc moreprmt_loop3
		ldx #0
moreprmt_loop4:
		pla
		sta varbuf,x
		inx
		cpx #5
		bcc moreprmt_loop4
		rts

newdate:
		ldx #var_an_string
		jsr usevar
		lda varbuf
		cmp #11
		bne newd0
		ldy #7
		lda (varbuf+1),y
		and #'1'
		cmp #'1'
		bne newd2
		iny
		lda (varbuf+1),y
		cmp #'2'
		bne newd2
		lda #'0'
		sta (varbuf+1),y
		dey
		lda (varbuf+1),y
		and #'8'
		sta (varbuf+1),y
newd2:
		dec varbuf
		inc varbuf+1
		bne newd1
		inc varbuf+2
newd1:
		ldx #var_an_string
		jsr putvar
newd0:
		rts

strscan:
		sty strsc2+1
		ldx #var_an_string
		jsr usevar
		ldy #0
		ldx #0
		lda varbuf
		beq strsc3
strsc1:
		lda (varbuf+1),y
		dec varbuf
		inc varbuf+1
		bne strsc2
		inc varbuf+2
strsc2:
		cmp #32
		beq strsc3
		sta buf2,x
		inx
		lda varbuf
		bne strsc1
strsc3:
		stx index
		ldx #var_an_string
		jsr putvar
		lda index
		sta varbuf
		lda #<buf2
		sta varbuf+1
		lda #>buf2
		sta varbuf+2
		ldx #var_a_string
		jmp putvar

