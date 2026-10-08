.encoding "petscii_mixed"

#import "equat.s"

* = protostart "copier.prg"

.label status = $90

.label gcount = 11
.label bcount = 23
.label ncount = 38

.label pbuf0= $658
.label pbuf1= $400
.label pbuf2= $500

proto:
		inx
		beq protonum
		dex
		beq copyall //&,16,0
		dex
		beq jcount //&,16,1
		dex
		beq copysome//&,16,2
		rts

jcount:
		jmp count

protonum:
		lda #0
		sta varbuf
		lda #2
		sta varbuf+1
		ldx #var_a_integer
putvar:
		lda #30
		jmp usetbl1

copysome:
		ldx #3
		jsr chkin
		jsr getin
		sta flen
		jsr getin
		sta flen+1
		jsr getin
		sta flen+2
		jsr clrchn
		jmp copy

copyall:
		lda #$ff
		sta flen
		sta flen+1
		sta flen+2
copy:
		lda #0
		sta done
cp1:
		ldx #3
		jsr chkin
		ldy #0
		ldx #0
cp2:
		jsr chrin
		sta pbuf1,y
		iny
		lda flen
		bne cp4
		lda flen+1
		bne cp3
		dec flen+2
cp3:
		dec flen+1
cp4:
		dec flen
		lda flen
		ora flen+1
		ora flen+2
		bne cp5
		inc done
		bne cp6
cp5:
		cpy #254
		beq cp6
		lda $90
		beq cp2
		inc done
cp6:
		sty buflen
		jsr clrchn
		ldx #2
		jsr chkout
		ldy #0
cp7:
		lda pbuf1,y
		jsr chrout
		iny
		cpy buflen
		bne cp7
		jsr clrchn
		jsr goodblok
		lda done
		beq cp1
		rts

count:
		ldx #3
		jsr chkin
		lda #0
		sta flen
		sta flen+1
		sta flen+2
count1:
		jsr getin
		inc flen
		bne nxtcount
		inc flen+1
		bne nxtcount
		inc flen+2
nxtcount:
		jsr goodbyte
		lda status
		beq count1
		jsr clrchn
		ldx #2
		jsr chkout
		lda flen
		jsr chrout
		lda flen+1
		jsr chrout
		lda flen+2
		jsr chrout
		jsr clrchn
		lda #3
		jmp $ffc3 // close

buflen:
		.byte 0
flen:
		.byte 0,0,0
done:
		.byte 0

goodbyte:
		ldx #ncount
		ldy #6
		jmp counter
goodblok:
		ldx #gcount
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
