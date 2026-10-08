#import "equat.s"

* = protostart "sort.prg"

.label ilen = $61 //1
.label istr = $62 //2
.label iptr = $64 //2
.label jlen = $69 //1
.label jstr = $6a //2
.label jptr = $6c //2
.label temp = $14 //2

// sys 49152,a$(1),n

		jmp sort

i:
		.word 0
j:
		.word 0
n:
		.word 0
base:
		.word 0

calcptr:
		stx temp
		sty temp+1
		txa
		asl
		tax
		tya
		rol
		tay
		clc
		txa
		adc temp
		tax
		tya
		adc temp+1
		tay
		clc
		txa
		adc base
		tax
		tya
		adc base+1
		tay
		rts
calcstr:
		stx temp
		sty temp+1
		ldy #0
		lda (temp),y
		pha
		iny
		lda (temp),y
		tax
		iny
		lda (temp),y
		tay
		pla
		rts

sort:
		lda #r6510_normal
		sta r6510
		jsr $aefd
		jsr $b08b
		ldx $47
		ldy $48
		stx base
		sty base+1
		jsr $aefd
		jsr $ad8a
		jsr $b7f7
		ldx $14
		ldy $15
		stx n
		sty n+1
		ldx #0
		ldy #0
sort0:
		inx
		bne sort1
		iny
sort1:
		stx i
		sty i+1
		jsr calcptr
		stx iptr
		sty iptr+1
		jsr calcstr
		sta ilen
		stx istr
		sty istr+1
		ldx i
		ldy i+1
		cpx n
		bne sort2
		cpy n+1
		bne sort2
		rts
sort2:
		inx
		bne sort3
		iny
sort3:
		stx j
		sty j+1
		jsr calcptr
		stx jptr
		sty jptr+1
		jsr calcstr
		sta jlen
		stx jstr
		sty jstr+1
		ldy #0
sort4:
		lda (istr),y
		cmp (jstr),y
		bne sort6
		iny
		cpy ilen
		bcs sort5
		cpy jlen
		bcc sort4
sort5:
		ldy ilen
		cpy jlen
sort6:
		beq sort8
		bcc sort8
		ldy #2
sort7:
		lda ilen,y
		sta (jptr),y
		lda jlen,y
		sta (iptr),y
		sta ilen,y
		dey
		bpl sort7
sort8:
		ldx j
		ldy j+1
		cpx n
		bne sort2
		cpy n+1
		bne sort2
		ldx i
		ldy i+1
		jmp sort0
