.encoding "petscii_mixed"

#import "equat.s"

* = protostart "net.prg"

.label t3 = 70

.label mfile = 131 //modem file number
.label dfile = 2 //disk file number
.label errch = 15 //disk error channel

.label xxx = 0
.label goo = 1
.label bad = 2
.label ack = 3
.label snb = 4
.label syn = 5

.label gcount = 11
.label bcount = 23
.label ncount = 38

.label pbuf0= $658
.label pbuf1= $400
.label pbuf2= $500

.label reset = rsinabl

		jmp entry

relaxflg:
		.byte 0

//serialp:
//		.byte "A"
//serialn:
//		.word 3

//code accept
t1:
		.byte 35,100
//receive timing
t2:
		.byte 16,30

entry:
		txa
		tsx
		stx stack
		tax
		lda #0
		sta tcount
		lda #r6510_normal
		sta r6510
		tya
		inx
		dex
		beq jupload //0
		dex
		beq jdnload //1
		dex
		beq jupname //2
		dex
		beq jdnname //3
		dex
		beq juprelx //4
		dex
		beq jdnrelx //5
		dex
		beq jmodemx //6
		rts

jupname:
		jmp trantype
jdnname:
		jmp rectype
jupload:
		jmp transmit
jdnload:
		jmp receive
juprelx:
		jmp tranrelx
jdnrelx:
		jmp recvrelx
jmodemx:
		jmp modemchk

// check carrier/abort
exit:
//		txa
//		pha
		lda $28d
		cmp #2
		beq ext1
//		ldx #4
//		lda bsnpre-4,x
//		cmp serialp-4,x
//		lda bsnval-4,x
//		cmp serialn-4,x
//		lda bsnval-3,x
//		cmp serialn-3,x
		lda carrst
		bmi ext2
ext1:
		ldx stack
		txs
		ldx #xxx
		jsr sendcode
ext0:
		lda #1
		sta 512
		jsr nobytes
ext2:
//		pla
//		tax
		rts

// get # bytes and exit
xfer1:
		lda blocks
		sta varbuf+1
		lda blocks+1
		sta varbuf
		ldx #var_b_integer
		jsr putvar
		lda #0
		sta 512
		rts

// check for code
accept:
		sta bitpat
		lda #$00
		sta codebuf
		sta codebuf+1
		sta codebuf+2
acc1:
		lda #$00
		sta tmer1
		sta tmer1+1
acc2:
		jsr getnumx
		bcs acc6
acc3:
		ldx codebuf+1
		stx codebuf
		ldx codebuf+2
		stx codebuf+1
		sta codebuf+2
		jsr chkcod
		beq acc1
		sec
		lda #$00
acc4:
		rol
		dex
		bpl acc4
		and bitpat
		beq acc2
		lda relaxflg
		bne acc5
		jsr getnumx
		bcc acc3
acc5:
		ldx bitcnt
		lda #0
		sta tcount
		sta $96
		rts
acc6:
		inc tmer1
		bne acc7
		inc tmer1+1
acc7:
		lda tmer1+1
		ldx relaxflg
		cmp t1,x
		bne acc2
		inc tcount
		lda tcount
		cmp #20
		bcc acc8
		jmp ext1
acc8:
		lda #1
		sta $96
		rts

chkcod:
		ldx #syn
chc1:
		lda codebuf
		cmp char1,x
		bne chc2
		lda codebuf+1
		cmp char2,x
		bne chc2
		lda codebuf+2
		cmp char3,x
		beq chc3
chc2:
		dex
		bpl chc1
chc3:
		stx bitcnt
		txa
		cmp #xxx
		bne chc4
		jmp ext1
chc4:
		cmp #255
		rts

//codes.........012345
char1:
		.byte ascii_ctrl_x
		.text "gbass"
char2:
		.byte ascii_ctrl_x
		.text "oac/y"
char3:
		.byte ascii_ctrl_x
		.text "odkbn"

sendcode:
		txa
		pha
		ldx #mfile
		jsr chkout
		pla
		tax
		lda char1,x
		jsr chrout
		lda char2,x
		jsr chrout
		lda char3,x
		jsr chrout
		jsr clrchn
		ldx #1
		jmp tenwait

getnumx:
		jsr exit
getnum1:
		lda #2
		sta $96
		lda #0
		sta $0200
		lda 667
		cmp 668
		beq getnum2
		tya
		pha
		txa
		pha
		jsr getmdm
		sta $0200
		pla
		tax
		pla
		tay
		lda #0
		sta $96
		clc
getnum2:
		lda $0200
		rts

tranrelx:
		lda #128
		sta repeat
trx1:
		ldx #syn
		jsr sendcode
		lda #(1<<syn) | (1<<goo)
		jsr accept
		beq trx3
		dec repeat
		bne trx1
trx2:
		lda #1
		sta $200
		rts
trx3:
		cpx #syn
		bne trx2
		lda #0
		sta $200
		rts

recvrelx:
		lda #1
		sta relaxflg
		lda #128
		sta repeat
rrx1:
		lda #(1<<syn) | (1<<goo)
		jsr accept
		beq rrx2
		dec repeat
		bne rrx1
		lda #1
		sta $200
		rts
rrx2:
		cpx #syn
		beq rrx3
		lda #0
		sta relaxflg
rrx3:
		ldx #syn
		jsr sendcode
		lda #0
		sta $200
		rts

rechand:
		sta gbsave
		lda recsize
		sta bufcount
		lda #0
		sta delay
rch1:
		lda #2
		sta repeat
		ldx gbsave
		jsr sendcode
rch2:
		lda #1<<ack
		jsr accept
		beq rch3
		dec repeat
		bne rch2
		jmp rch1
rch3:
		ldx #snb
		jsr sendcode
		lda endflag
		beq rch4
		lda gbsave
		cmp #goo
		beq rch6
rch4:
		jsr recmodem
		ldx $96
		stx pbuf0+1
		cpx #2
		beq rch3
		cpx #4
		beq rch3
rch5:
		lda $96
		rts
rch6:
		lda #1<<syn
		jsr accept
		bne rch1
		lda #3
		sta repeat
rch7:
		ldx #syn
		jsr sendcode
		lda #1<<snb
		jsr accept
		beq rch8
		dec repeat
		bne rch7
rch8:
		rts

trh0:
		jmp ext1
tranhand:
		lda #$01
		sta delay
		lda #30
		sta repeat
trh1:
		dec repeat
		beq trh0
		lda specmode
		beq trh2
		ldx #goo
		jsr sendcode
trh2:
		lda #(1<<goo) | (1<<bad) | (1<<snb)
		jsr accept
		bne trh1
		lda #0
		sta specmode
		cpx #goo
		bne trh6
		lda endflag
		bne trh8
		inc blocknum
		bne trh3
		inc blocknum+1
trh3:
		jsr thisbuf
		ldy #5+1
		lda ($64),y
		cmp #$ff
		bne trh4
		lda #$01
		sta endflag
		lda bufpnt
		eor #$01
		sta bufpnt
		jsr thisbuf
		jsr dummybl1
		jmp trh5
trh4:
		jsr dummyblk
trh5:
		lda #'-'
		.byte $2c
trh6:
		lda #':'
		jsr prtdash
		lda #0
		sta ackcount
trh6a:
		inc ackcount
		lda ackcount
		cmp #20
		bcc trh6b
		jmp ext1
trh6b:
		ldx #ack
		jsr sendcode
		lda #1<<snb
		jsr accept
		bne trh6a
		jsr thisbuf
		ldy #4
		lda ($64),y
		sta bufcount
		jsr altbuf
		ldx #mfile
		jsr chkout
		ldy #0
trh7:
		lda ($64),y
		jsr chrout
		iny
		cpy bufcount
		bne trh7
		jsr clrchn
		lda #$00
		rts
trh8:
		lda #'*'
		jsr prtdash
		ldx #ack
		jsr sendcode
		lda #1<<snb
		jsr accept
		bne trh8
// lda #10
// sta bufcount
trh9:
		ldx #syn
		jsr sendcode
		lda #1<<syn
		jsr accept
// bne trha
// dec bufcount
// bne trh9
//trha:
//		lda #3
//		sta bufcount
trhb:
		ldx #snb
		jsr sendcode
// lda #0
// jsr accept //wait
// dec bufcount
// bne trhb
		lda #1
		rts

//returns:

// 1 = buffer is full
// 2 = timeout, stuff in buffer
// 3 = timeout, buffer empty
// 4 = timeout, "ack" in buffer
recmodem:
		ldy #$00
		lda recsize
		sta pbuf2+1
rcm1:
		lda #$00
		sta pbuf0+1
		sta tmer1
		sta tmer1+1
rcm2:
		jsr getnumx
		lda $96
		bne rcm5
		lda $0200
		sta pbuf1,y
		cpy #$02
		bne rcm3
		lda pbuf1
		cmp #'a'
		bne rcm3
		lda pbuf1+1
		cmp #'c'
		bne rcm3
		lda pbuf1+2
		cmp #'k'
		beq rcm4
rcm3:
		iny
		cpy recsize
		bne rcm1
		lda #1
		sta $96
		rts
rcm4:
		lda #$ff
		sta tmer1
		sta tmer1+1
		jmp rcm2
rcm5:
		inc tmer1
		bne rcm6
		inc tmer1+1
rcm6:
		lda tmer1
		ora tmer1+1
		beq rcm8
		lda tmer1+1
		ldx relaxflg
		cmp t2,x
		bne rcm2
		lda #2
		sta $96
		cpy #$00
		beq rcm7
		lda #3
		sta $96
rcm7:
		jmp dodelay
rcm8:
		lda #4
		sta $96
		jmp clrchn

dummyblk:
		lda bufpnt
		eor #$01
		sta bufpnt
		jsr thisbuf
		ldy #$05
		lda blocknum
		clc
		adc #$01
		sta ($64),y
		iny
		lda blocknum+1
		adc #$00
		sta ($64),y
		ldx #dfile
		jsr chkin
		ldy #7
dum1:
		jsr chrin
		sta ($64),y
		iny
		jsr readst
		bne dum2
		cpy maxsize
		bne dum1
		tya
		pha
		jmp dum3
dum2:
		tya
		pha
		ldy #5+1
		lda #$ff
		sta ($64),y
		jmp dum3
dummybl1:
		pha
dum3:
		jsr clrchn
		jsr reset
		jsr dod2
		jsr reset
		ldy #$04
		lda ($64),y
		sta bufcount
		jsr altbuf
		pla
		ldy #$04
		sta ($64),y
		jsr checksum
		rts

thisbuf:
		lda #<pbuf1
		sta $64
		lda bufpnt
		clc
		adc #>pbuf1
		sta $65
		rts

altbuf:
		lda #<pbuf1
		sta $64
		lda bufpnt
		eor #1
		clc
		adc #>pbuf1
		sta $65
		rts

checksum:
		lda #$00
		sta check1
		sta check1+1
		sta check1+2
		sta check1+3
		ldy #$04
chk1:
		lda check1
		clc
		adc ($64),y
		sta check1
		bcc chk2
		inc check1+1
chk2:
		lda check1+2
		eor ($64),y
		sta check1+2
		lda check1+3
		rol
		rol check1+2
		rol check1+3
		iny
		cpy bufcount
		bne chk1
		ldy #3
l1:
		lda check1,y
		sta ($64),y
		dey
		bpl l1
		rts

transmit:
		jsr screen
		lda #$00
		sta endflag
		sta skpdelay
		sta dontdash
		lda #$01
		sta bufpnt
		lda #$ff
		sta blocknum
		sta blocknum+1
		jsr altbuf
		ldy #4
		lda #7
		sta ($64),y
		jsr thisbuf
		ldy #5
		lda #0
		sta ($64),y
		iny
		sta ($64),y
tra1:
		jsr tranhand
		beq tra1
tra2:
		jmp xfer1

receive:
		jsr screen
		lda #$01
		sta blocknum
		lda #$00
		sta blocknum+1
		sta endflag
		sta bufpnt
		sta pbuf1+5
		sta pbuf1+6
		sta skpdelay
		ldx #7
		stx recsize
		lda #goo
rec1:
		jsr rechand
		lda endflag
		bne tra2
		jsr match
		bne rec5
		lda recsize
		cmp #7
		beq rec3
		ldx #dfile
		jsr chkout
		ldy #7
rec2:
		lda pbuf1,y
		jsr chrout
		iny
		cpy bufcount
		bne rec2
		jsr clrchn
rec3:
		lda pbuf1+6
		cmp #$ff
		bne rec4
		lda #1
		sta endflag
rec4:
		jsr goodblok
		jsr dobytes
		jsr reset
		ldx pbuf1+4
		stx recsize
		lda #goo
		jmp rec1
rec5:
		jsr badblok
		lda #bad
		jmp rec1

match:
		ldx #3
mch1:
		lda pbuf1,x
		sta check,x
		dex
		bpl mch1
		jsr thisbuf
		lda recsize
		sta bufcount
		jsr checksum
		ldx #3
mch2:
		lda pbuf1,x
		cmp check,x
		bne mch3
		dex
		bpl mch2
		lda #0
		rts
mch3:
		lda #1
		rts

rectype:
		jsr screen
		lda #$00
		sta blocknum
		sta blocknum+1
		sta endflag
		sta bufpnt
		sta skpdelay
		lda #goo
rct1:
		ldx #7+32
		stx recsize
		jsr rechand
		inc pbuf2
		lda endflag
		bne rct3
		jsr match
		bne rct2
		jsr buf2var
		lda #1
		sta endflag
		lda #goo
		jmp rct1
rct2:
		lda #bad
		jmp rct1
rct3:
		lda #0
		sta $0200
		rts

trantype:
		jsr screen
		lda #$00
		sta endflag
		sta skpdelay
		sta dontdash
		lda #$01
		sta bufpnt
		lda #$ff
		sta blocknum
		sta blocknum+1
		jsr altbuf
		ldy #4
		lda #7+32
		sta ($64),y
		jsr thisbuf
		ldy #5
		lda #$ff
		sta ($64),y
		iny
		sta ($64),y
		jsr var2buf
		lda #1
		sta specmode
trt1:
		jsr tranhand
		beq trt1
		lda #0
		sta $0200
		rts

var2buf:
		lda $64
		sta var2buf3+1
		lda $65
		sta var2buf3+2
		ldx #var_b_string
		jsr usevar
		ldy #0
		ldx #7
var2buf2:
		cpy varbuf
		beq var2buf4
		lda (varbuf+1),y
var2buf3:
		sta $ffff,x
		iny
		inx
		bne var2buf2
var2buf4:
		txa
		tay
		lda var2buf3+1
		sta $64
		lda var2buf3+2
		sta $65
		lda #13
		sta ($64),y
		iny
		rts

buf2var:
		ldx #7
		ldy #0
buf2var1:
		lda pbuf1,x
		cmp #13
		beq buf2var2
		sta buffer,y
		iny
		inx
		cpy #79
		bcc buf2var1
buf2var2:
		tya
		jsr makerm1
		ldy #0
buf2var3:
		cpy varbuf
		beq buf2var4
		lda buffer,y
		sta (varbuf+1),y
		iny
		bne buf2var3
buf2var4:
		ldx #var_b_string
		jmp putvar

dodelay:
		inc skpdelay
		lda skpdelay
		cmp #$03
		bcc dod1
		lda #$00
		sta skpdelay
		lda delay
		beq dod2
		bne dod5
dod1:
		lda delay
		beq dod5
dod2:
		ldx #$00
dod3:
		ldy #$00
dod4:
		iny
		bne dod4
		inx
		cpx #$78
		bne dod3
dod5:
		rts

prtdash:
		pha
		lda blocknum
		ora blocknum+1
		beq prd1
		lda dontdash
		bne prd1
		pla
		jsr dodash
		pha
prd1:
		pla
		rts

dodash:
		sta dash
		cmp #'*'
		beq dsh2
		cmp #'-'
		beq dsh1
		jmp badblok
dsh1:
		jsr goodblok
dsh2:
		jmp dobytes

screen:
		lda #0
		sta badcount
		jsr reset
		jsr nobytes
		lda #52
		ldx #16
		ldy #0
		jmp usetbl1

nobytes:
		lda #0
		sta bytes
		sta bytes+1
		sta bytes+2
		sta blocks
		sta blocks+1
		sta bytec
		sta bytec+1
		rts

dobytes:
		lda bufcount
		sec
		sbc #7
		pha
		clc
		adc bytes
		sta bytes
		bcc dobytes1
		inc bytes+1
		bne dobytes1
		inc bytes+2
dobytes1:
		pla
		clc
		adc bytec
		sta bytec
		bcs dobytes2
		inc bytec+1
dobytes2:
		lda bytec
		bne dobytes3
		lda bytec
		cmp #254
		bcs dobytes3
		rts
dobytes3:
		lda bytec
		sec
		sbc #254
		sta bytec
		lda bytec+1
		sbc #0
		sta bytec+1
		inc blocks
		bne dobytes4
		inc blocks+1
dobytes4:
		rts

bytes:
		.byte 0,0,0
bytec:
		.word 0
blocks:
		.word 0
bitpnt:
		.byte $20
bitcnt:
		.byte $0f
bitpat:
		.byte $04
tmer1:
		.word $0000
gbsave:
		.byte $00
bufcount:
		.byte $07
delay:
		.byte $00
skpdelay:
		.byte $00
endflag:
		.byte $00
check:
		.word $0000,$0000
check1:
		.word $0000,$0000
bufpnt:
		.byte $00
recsize:
		.byte $07
maxsize:
		.byte $ff
blocknum:
		.word $0000
stack:
		.byte $f6
dontdash:
		.byte $00
specmode:
		.byte $00
dash:
		.byte $00
codebuf:
		.text "   "
numx:
		.byte 0
repeat:
		.byte 0
badcount:
		.byte 0
tcount:
		.byte 0
ackcount:
		.byte 0
badblks:
		.word 0

getln:
		lda #35
		jmp usetbl1
putln:
		lda #36
		jmp usetbl1
getmdm:
		lda #4
		jmp usetbl1
usevar:
		lda #29
		jmp usetbl1
putvar:
		lda #30
		jmp usetbl1
tenwait:
		lda #22
		jmp usetbl1
xchrout:
		sta $fe
		lda #24
		jmp usetbl1
minusone:
		lda #32
		jmp usetbl1

modemchk:
		sty index
		ldx #var_a_string
		jsr usevar
		lda varbuf
		beq modemc2
		ldx #mfile
		jsr chkout
		ldy #0
modemc1:
		lda (varbuf+1),y
		jsr chrout
		iny
		cpy varbuf
		bcc modemc1
		jsr clrchn
modemc2:
		ldy #0
		sty varbuf
modemc3:
		lda #0
		sta tmer1
		sta tmer1+1
modemc4:
		lda 653
		cmp #2
		beq modemc6
		lda carrst
		bpl modemc6
		jsr getmdm
		and #127
		bne modemc7
		inc tmer1
		bne modemc5
		inc tmer1+1
modemc5:
		lda tmer1+1
		cmp #100
		bcc modemc4
		jmp modemc9
modemc6:
		jsr minusone
		ldx #var_rc_float
		jsr putvar
		lda #0
		sta varbuf
		jmp modemc9
modemc7:
		cmp #13
		beq modemc10
		cmp #32
		bcc modemc3
		cmp #96
		bcc modemc10
		sec
		sbc #32
modemc10:
		ldy varbuf
		sta buffer,y
		inc varbuf
		jsr xchrout
		ldy varbuf
		cpy index
		beq modemc3
		bcc modemc3
		ldy #0
modemc8:
		lda buffer+1,y
		sta buffer,y
		iny
		cpy index
		bcc modemc8
		sty varbuf
		jmp modemc3
modemc9:
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2
		ldx #var_b_string
		jmp putvar

//increment byte count
commbyte:
		tya
		pha
		ldy #6
		ldx #ncount
		jsr counter
		inc bytes
		bne cmb6
		inc bytes+1
		bne cmb6
		inc bytes+2
cmb6:
		pla
		tay
		rts
commcnt:
		.byte 0

//increment good blocks
goodblok:
		inc blocks
		bne goodb1
		inc blocks+1
goodb1:
		ldx #gcount
		jmp counter0

//increment bad blocks
badblok:
		inc badblks
		bne badb1
		inc badblks+1
badb1:
		ldx #bcount

counter0:
		ldy #5
counter:
		inc pbuf0,x
		lda pbuf0,x
		cmp #':'
		bne counter1
		lda #'0'
		sta pbuf0,x
		dex
		dey
		bne counter
counter1:
		rts
