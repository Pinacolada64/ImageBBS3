.encoding "petscii_mixed"

#import "equat.s"

* = protostart "copier.prg"

// ++ copier: the file "protocol" used in Console Local mode, and by i.CP
// (Copy-All). It copies between two files BASIC has already opened:
// file #3 is read, file #2 is written. Nothing is closed except as noted.
//
// &,16,0    copy all of #3 to #2, in blocks of up to 254 bytes, until
//           the end of #3 (status <> 0); "Good:" counts the blocks
// &,16,1    count the bytes in #3 ("Bytes:" counts them), write the count
//           to #2 as 3 bytes (low, middle, high), then close #3
// &,16,2    read a 3-byte count (low, middle, high) from #3, then copy
//           that many more bytes of #3 to #2, as &,16,0 does
// &,16,255  a% = 2, the protocol number
//
// &,16,1 then &,16,0 into the same #2 writes a file behind its length;
// &,16,2 on that copies the file back out, stopping at its end (so more
// can follow it).
//
// The counters are the digits of the protocol screen's row 15
// (" Good: 00000  Bad: 00000  Bytes: 000000 ", drawn by sub.display):
// pbuf0 is that row of screen memory, and gcount/bcount/ncount the
// columns of each counter's last digit. Bad: isn't used here.

.label status = $90

.label gcount = 11 // last digit of "Good:"
.label bcount = 23 // last digit of "Bad:" (not used)
.label ncount = 38 // last digit of "Bytes:"

.label pbuf0= $658 // screen memory, row 15
.label pbuf1= $400 // copy buffer (one block)
.label pbuf2= $500

// &,16,x passes x in X: 255 (wraps to 0 on inx) = protocol number,
// then 0, 1, 2
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

// &,16,255: a% = 2
protonum:
		lda #0
		sta varbuf
		lda #2
		sta varbuf+1
		ldx #var_a_integer
putvar:
		lda #30
		jmp usetbl1

// &,16,2: the count to copy is the first 3 bytes of #3
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

// &,16,0: count = $ffffff, so the copy ends at end of file
copyall:
		lda #$ff
		sta flen
		sta flen+1
		sta flen+2
// copy #3 to #2 a block at a time, until the count runs out or #3 ends
copy:
		lda #0
		sta done
// read up to 254 bytes into pbuf1, counting flen down
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
// write the block to #2, add 1 to "Good:"; again unless done
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

// &,16,1: count the bytes of #3, adding 1 to "Bytes:" for each
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
// write the count to #2, low byte first, and close #3
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
		.byte 0 // bytes in pbuf1
flen:
		.byte 0,0,0 // byte count, low byte first
done:
		.byte 0 // nonzero: last block

// add 1 to the 6-digit "Bytes:" counter on the screen
goodbyte:
		ldx #ncount
		ldy #6
		jmp counter
// add 1 to the 5-digit "Good:" counter on the screen
goodblok:
		ldx #gcount
		ldy #5
// add 1 to the Y-digit counter whose last digit is at pbuf0+X
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
