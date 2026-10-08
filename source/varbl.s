//********************************
//* variable handling routines *
//********************************

//* get descriptor for tt$(.x)
getarr:
		jsr findarr
		ldy #2
		jmp usevar1

//* get and copy memory to buffer
getln:
		jsr getarr
		ldy varbuf
		sty index
getln0:
		dey
		cpy #$ff
		beq getln1
		cpy #80
		bcs getln0
		lda (varbuf+1),y
		sta buffer,y
		jmp getln0
getln1:
		rts

//* print tt$(.a)
prtln:
		jsr getarr
		jmp outstr

//* put descriptor for tt$(.x) and
//* store buffer in memory
putarr:
		jsr findarr
		ldy #2
		jmp putvar1

//* put and store string
putln:
		txa
		pha
		lda index
		jsr makeroom
		ldy index
		beq putln2
		dey
putln1:
		lda buffer,y
		sta (varbuf+1),y
		dey
		bpl putln1
putln2:
		pla
		tax
		jmp putarr

//* find descriptor for tt$(.x)
findarr:
		stx $47
		lda #0
		asl $47
		rol
		sta $48
		txa
		clc
		adc $47
		sta $47
		lda #0
		adc $48
		sta $48
		clc
		lda $2f
		adc $47
		sta $47
		lda $30
		adc $48
		sta $48
		clc
		lda #7
		adc $47
		sta $47
		lda #0
		adc $48
		sta $48
		rts

// Find address of basic variable by index
// input
//   X = variable index
// returns
//   A = trashed
//   X = LSB of address
//   Y = MSB of address

gvarptr:
		txa
		asl
		tay
		clc
		lda vars,y
		adc $2d
		tax
		lda vars+1,y
		adc $2e
		tay
		rts

varnam:
		jsr gvarptr
		stx $47
		sty $48
		rts

findvar:
		sta $45
		stx $46
		jmp findvar1

//* print string variable
prtvar:
		jsr usevar
		jmp outstr

//* print string variable w/mci
prtvar0:
		lda mci
		pha
		lda #0
		sta mci
		jsr prtvar
		pla
		sta mci
		rts

//* get variable descriptor
usevar:
		jsr varnam
		jmp usevar2
usevar0:
		jsr findvar
usevar2:
		ldy #4
usevar1:
		lda ($47),y
		sta varbuf,y
		dey
		bpl usevar1
		rts

//* put variable descriptor
putvar:
		jsr varnam
		jmp putvar2
putvar0:
		jsr findvar
putvar2:
		ldy #4
putvar1:
		lda varbuf,y
		sta ($47),y
		dey
		bpl putvar1
		rts

zero:
		lda #0
		ldy #4
zero1:
		sta varbuf,y
		dey
		bpl zero1
		rts
minusone:
		jsr zero
		lda #$81
		sta varbuf
		rts

//********************************
//* variables used by ml *
//********************************

// the values here are replaced by offsets into
// the variable area by the intro code
vars:
		.byte $41, $ce         //  0 an$
		.byte $41, $80         //  1 a$
		.byte $42, $80         //  2 b$
		.byte $54, $d2         //  3 tr$
		.byte $44, $b1         //  4 d1$
		.byte $44, $b2         //  5 d2$
		.byte $44, $b3         //  6 d3$
		.byte $44, $b4         //  7 d4$
		.byte $44, $b5         //  8 d5$
		.byte $4c, $c4         //  9 ld$
		.byte $54, $d4         // 10 tt$
		.byte $4e, $c1         // 11 na$
		.byte $52, $ce         // 12 rn$
		.byte $50, $c8         // 13 ph$
		.byte $41, $cb         // 14 ak$
		.byte $4c, $50         // 15 lp
		.byte $50, $4c         // 16 pl
	 	.byte $52, $43         // 17 rc
		.byte $53, $48         // 18 sh
		.byte $4d, $57         // 19 mw
		.byte $4e, $4c         // 20 nl
		.byte $55, $4c         // 21 ul
		.byte $51, $45         // 22 qe
		.byte $52, $51         // 23 rq
		.byte $c1, $c3         // 24 ac%
		.byte $45, $46         // 25 ef
		.byte $4c, $46         // 26 lf
		.byte $57, $80         // 27 w$
		.byte $50, $80         // 28 p$
		.byte $d4, $d2         // 29 tr%
		.byte $c1, $80         // 30 a%
		.byte $c2, $80         // 31 b$
		.byte $c4, $d6         // 32 dv%
		.byte $44, $d2         // 33 dr$
		.byte $43, $b1         // 34 c1$
		.byte $43, $b2         // 35 c2$
		.byte $43, $cf         // 36 co$
		.byte $43, $c8         // 37 ch$
		.byte $cb, $d0         // 38 kp%
		.byte $43, $b3         // 39 c3$
		.byte $46, $b1         // 40 f1$
		.byte $46, $b2         // 41 f2$
		.byte $46, $b3         // 42 f3$
		.byte $46, $b4         // 43 f4$
		.byte $46, $b5         // 44 f5$
		.byte $46, $b6         // 45 f6$
		.byte $46, $b7         // 46 f7$
		.byte $46, $b8         // 47 f8$
		.byte $4d, $d0         // 48 mp$
		.byte $cd, $ce         // 49 mn%
