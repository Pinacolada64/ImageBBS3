.label devnum = 186

// intro is a proto
		jmp intro
		jmp setup
		.byte $ff //intro


//* intro program

intro:

//fake rs232 driver filled with "RTS" instructions

		lda #$60
		ldy #0
intro_loop1:
		sta rs232,y
		dey
		bne intro_loop1

// move editor code to it's "swapped out" location
// also moves other modules after the editor
// TODO split this out to swap each module individually

		lda #>editor_load_address
		ldy #>editor_swap_address
		ldx #48
		jsr swapper

//move wedge to it's execution location

		lda #>wedge_load_address
		ldy #>wedge_exec_address
		ldx #>wedge_module_size
		jsr swapper

//load "im" basic program

		ldx #<prgstart
		ldy #>prgstart
		stx $2b
		sty $2c
		ldx #<(prgstart+2)
		ldy #>(prgstart+2)
		stx $2d
		sty $2e
		stx $2f
		sty $30
		stx $31
		sty $32
		lda #0
		sta prgstart-1
		sta prgstart
		sta prgstart+1
		lda #1
		ldx devnum
		ldy #0
		jsr $ffba
		lda file2
		ldx #<(file2+1)
		ldy #>(file2+1)
		jsr $ffbd
		jsr loadprg
		lda #1
		sta loadflag
//restore screen
		lda #11
		sta $d011
		lda #$17
		sta $d018
		lda #clear_screen
		jsr $e716
		lda #27
		sta $d011
//fake lightbar table
		lda #0
		ldy #0
intro_loop2:
		sta chktbl,y
		iny
		cpy #16
		bne intro_loop2
		lda #32
		ldy #0
intro_loop3:
		sta bartbl,y
		iny
		cpy #192
		bne intro_loop3
//run program
		lda #0
		jsr $a871
		jmp $a7ae

//* filenames
file2:
		.byte 2
		.text "im"

//* setup routines *

//* main setup routine
setup:
		lda #0
		tay
setup_loop1:
		sta cassbuff,y
		iny
		cpy #1024-cassbuff
		bne setup_loop1
		ldy #0
setup_loop2:
		lda date2,y
		sta date1,y
		iny
		cpy #28
		bne setup_loop2
		lda #80
		sta ptrclmn
		lda #40
		sta modclmn
		lda #1
		sta local
		ldy #0
setup_loop3:
		lda #32
		sta tempscn+$00,y
		sta tempscn+$a0,y
		lda #1
		sta tempcol+$00,y
		sta tempcol+$a0,y
		iny
		cpy #$a0
		bne setup_loop3
		ldy #11
setup_loop4:
		lda daysofm0,y
		sta daysofm,y
		dey
		bpl setup_loop4
		jsr copytran
		ldy #15
		lda #16
setup_loop5:
		sta pmodetbl,y
		dey
		bpl setup_loop5
		lda #255
		sta pmodetbl+16
		lda #0
		sta pmodetbl+17
		ldy #0
setup_loop6:
		lda #1
		sta alarmtb,y
		lda #0
		sta alarmtb+1,y
		iny
		bpl setup_loop6
		ldy #12*3-1
setup_loop7:
		lda montbl0,y
		sta montbl,y
		dey
		bpl setup_loop7
		ldy #8*3-1
setup_loop8:
		lda daytbl0,y
		sta daytbl,y
		dey
 		bpl setup_loop8
		ldy #31
setup_loop9:
		lda date1fmt,y
		sta date1,y
		dey
		bpl setup_loop9
		ldy #64
setup_loop10:
		lda sndtbl0,y
		sta sndtbl,y
		dey
		bpl setup_loop10
		ldy #0
		ldx #0
setup_loop11:
		lda screentb,y
		iny
		sta lobytes,x
		lda screentb,y
		iny
		sta hibytes,x
		lda screentb,y
		iny
		sta lobytec,x
		lda screentb,y
		iny
		sta hibytec,x
		inx
		cpx #25
		bne setup_loop11

		lda $ffd2
		cmp #$20
		bne setup1
		jsr lockinit
setup1:
		lda #0
		sta passmode
		lda #'X'
		sta mask
		lda #2
		sta bar
		lda #0
		sta readmode
		sta scnmode
		sta scnlock
		sta interm
		sta inchat
		jsr iosetup
		jsr setptrs
		jsr setirq
		jsr trapoff
		lda #$36
		sta $01
		jsr setscrn
		ldx #3
		jsr comq
		jsr startmsg
		lda #$37
		sta $01
		rts

//* setup i/o windows

iosetup:
		lda $0326
		sta oldout+1
		lda $0327
		sta oldout+2
		lda #<newout
		sta $0326
		lda #>newout
		sta $0327
		rts

//* setup irq vector

setirq:
		lda #$1f
		sta d1icr
		lda #$ff
		sta timblo
		sta timbhi
		lda #$11
		sta ciacrb
		lda #<raster
		sta 788
		lda #>raster
		sta 789
		lda #$81
		sta $d01a
		lda #$00
		sta $d012
		lda #$1b
		sta $d011
		lda #0
		sta irqcount
		rts

//* initial setup of screen
//* colors/ clear/ etc
setscrn:
		lda #$00
		sta $d020
		lda #$00
		sta $d021
		lda #$0e
		jsr chrout
		lda #$08
		jsr chrout
		lda #$05
		jsr chrout
		jsr makdate
		jmp dispdate

//* find basic variable
getvarp:
		txa
		asl
		tay
		lda varlist+1,y
		tax
		lda varlist,y
		sta $45
		stx $46
		jmp findvar1

//********************************
//* variables used by ml *
//********************************

varlist:
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

//find all vars used by ml,
//get their pointers

setptrs:
		lda #49
		sta tmp1
setp1:
		ldx tmp1
		jsr getvarp
		lda tmp1
		asl
		tay
		sec
		lda $47
		sbc $2d
		sta vars,y
		lda $48
		sbc $2e
		sta vars+1,y
		dec tmp1
		bpl setp1
		rts

date2:
		.text "Sat Aug 08, 2020 12:25 PM   "

copytran:
		ldy #0
copytran_loop1:
		lda tr1,y
		sta tblatc,y
		iny
		cpy #128
		bcc copytran_loop1
		ldy #0
copytran_loop2:
		lda tr2,y
		sta tblcta,y
		iny
		bne copytran_loop2
		ldy #0
copytran_loop3:
		lda tr3,y
		sta tblcta1,y
		lda tr4,y
		sta tblcta2,y
		lda tr5,y
		sta tblcta3,y
		iny
		cpy #32
		bcc copytran_loop3
		rts

// tblatc
tr1:
		.byte $00,$00,$02,$00,$04,$00,$00,$00
		.byte $14,$09,$00,$00,$93,$0d,$0e,$0f
		.byte 0,$11,0,$13,20,$15,$16,$17,$18,$19,0,27,0,0,0,0
		.text " !"
		.byte 34
		.text "#$%&'()*+,-./"
		.text "0123456789:;<=>?"
		.text "@ABCDEFGHIJKLMNOPQRSTUVWXYZ["
		.byte $5c
		.text "]^_"
		.byte 0
		.text "abcdefghijklmnopqrstuvwxyz"
		.byte 0,0,0,0,20

// tblcta
.encoding "ascii"
tr2:
		.byte $00, $01, $02, $03, $04, $05, $06, $07
		.byte $08, $09, $0a, $0b, $0c, $0d, $00, $0f
		.byte $10, $11, $12, $13, $08, $15, $16, $17
		.byte $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
		.text " !"
		.byte 34
		.text "#$%&'()*+,-./"
		.text "0123456789:;<=>?"
		.text "@abcdefghijklmnopqrstuvwxyz[\]^_"
		.text "-ABCDEFGHIJKLMNOPQRSTUVWXYZ*-!**"
		.byte 0,129,0,0,0,0,0,0,0,0,0,0,0,$d,0,0
		.byte 0,145,146,12,0,149,150,151,152,153,154,155,156,157,158,159
		.text " !---!*!-*!****-"
		.text "****!!!---******"
		.text "-ABCDEFGHIJKLMNOPQRSTUVWXYZ*!!**"
		.text " !---!*!-*!****-"
		.text "****!!!---******"
.encoding "petscii_mixed"

// tblcta1
tr3:
		.byte 032,221,220,196,095,179,178,179
		.byte 220,047,222,195,201,192,191,220
		.byte 218,193,194,180,221,221,222,223
		.byte 223,220,217,187,200,217,188,176

// tblcta2
tr4:
		.byte 196,065,066,067,068,069,070,071
		.byte 072,073,074,075,076,077,078,079
		.byte 080,081,082,083,084,085,086,087
		.byte 088,089,090,197,221,179,178,092

// tblcta3
tr5:
		.byte 196,042,179,196,196,196,196,179
		.byte 179,191,192,217,192,092,047,218
		.byte 191,254,196,042,179,218,042,254
		.byte 042,179,042,197,221,179,227,092

//* months and days
montbl0:
		.text "JanFebMarAprMayJun"
		.text "JulAugSepOctNovDec"
daytbl0:
		.text "???SunMonTueWedThu"
		.text "FriSat"
daysofm0:
		.byte 31,28,31,30,31,30
		.byte 31,31,30,31,30,31

date1fmt:
		.text "Sat Dec  9, 2020"
		.text " 12:00 AM EST   "

sndtbl0:

//(0) beep
		.byte $00,$40,$10,$f0,$11
		.byte $00,$00,$00,$00,$00
		.byte $00,$00,$00,$00,$00
		.byte $10
//(1) ding
		.byte $44,$40,$0b,$00,$15
		.byte $00,$00,$00,$00,$00
		.byte $d8,$2a,$00,$00,$00
		.byte $50
//(2) bell
		.byte $00,$60,$09,$00,$11
		.byte $00,$60,$09,$00,$11
		.byte $00,$60,$09,$00,$11
		.byte $20
//(3) bong
		.byte $44,$10,$0d,$00,$15
		.byte $30,$08,$0b,$00,$15
		.byte $1c,$04,$0d,$00,$15
		.byte $e0

startmsg:
		lda #1
		sta local
		ldx #0
		jsr setmode
		lda #5
		jsr usetbl1
		lda #bootvers_end - bootvers
		sta varbuf
		lda #<bootvers
		sta varbuf+1
		lda #>bootvers
		sta varbuf+2
		ldx #var_an_string
		jsr putvar
		ldx #var_an_string
		jmp prtvar0

bootvers:
		.byte clear_screen
		.text " Image BBS V" + version_number + " "
		.byte british_pound
		.text "$a"
		.byte function_key_6
bootvers_end:


screentb:
		.word $400+000,$d800+000
		.word $400+040,$d800+040
		.word $400+080,$d800+080
		.word $400+120,$d800+120
		.word $400+160,$d800+160
		.word $400+200,$d800+200
		.word $400+240,$d800+240
		.word $400+280,$d800+280
		.word $400+320,$d800+320
		.word $400+360,$d800+360
		.word $400+400,$d800+400
		.word $400+440,$d800+440
		.word $400+480,$d800+480
		.word $400+520,$d800+520
		.word $400+560,$d800+560
		.word $400+600,$d800+600
		.word tempscn0,tempcol0
		.word tempscn1,tempcol1
		.word tempscn2,tempcol2
		.word tempscn3,tempcol3
		.word tempscn4,tempcol4
		.word tempscn5,tempcol5
		.word tempscn6,tempcol6
		.word tempscn7,tempcol7
		.word $400+960,$d800+960

lockinit:
		jsr ltk_bnkout
		lda ltk_activu
		pha
		lda ltk_activl
		pha
		lda #10
		jsr ltk_setlun
		lda #0
		sta ltk_activu
		jsr ltk_clrhdr
		ldy #0
lockinit_loop1:
		lda lockname,y
		beq lockint1
		sta filnam,y
		iny
		bne lockinit_loop1
lockint1:
		jsr ltk_fnfile
		bcs lkerror
		lda blmilo+1
		sta blkl_load+1
		lda blmilo+0
		sta blkh_load+1
		jsr ltk_getprt
		ora #$80
		sta port_load+1
lkerror:
		pla
		jsr ltk_setlun
		pla
		sta ltk_activu
		jsr ltk_bankin
		cli
		rts

lockname:
		.text "lockfile"
		.byte 0

