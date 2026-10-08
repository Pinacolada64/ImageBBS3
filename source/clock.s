#import "equat.s"

* = protostart "clock.prg"

.label screen= $0428
.label colorm= $d828
.label c1= 646

ml:
		jmp doclock

doclock0:
		rts
doclock:
		lda clock
		beq doclock0
		lda scs
		cmp clockscs
		beq doclock0
		sta clockscs
		lda hrs
		jsr bcdtob
		and #1
		sta h0
		sty h1
		lda min
		jsr bcdtob
		sta m0
		sty m1
		lda ten
		ldy #0
		lda h0
		bne ck3
		lda #10
		jsr quad
ck3:
		jsr quad
		lda h1
		jsr quad
		lda clockscs
		lsr
		lda #0
		adc #10
		jsr quad
		lda m0
		jsr quad
		lda m1
		jsr quad
		lda h0
		bne ck4
		lda #10
		jsr quad
		jsr quad
ck4:
		lda #160
		ldy c2
		sta screen+57
		sty colorm+57
		sta screen+97
		sty colorm+97
		sta screen+137
		sty colorm+137
		ldy #17
ck2:
		lda #160
		sta screen+160,y
		lda c2
		sta colorm+160,y
		dey
		bne ck2
		rts

bcdtob:
		pha
		and #$0f
		tay
		pla
		lsr
		lsr
		lsr
		lsr
		rts

h0:
		.byte 0
h1:
		.byte 0
m0:
		.byte 0
m1:
		.byte 0
clockscs:
		.byte 0
a:
		.byte 0
x:
		.byte 0
y:
		.byte 0
w:
		.byte 0
c2:
		.byte 11

charbuf:
		.fill 8, 0

quadchr:
		.byte 160,236,251,226,252,97,127,126,254,255,225,124,98,123,108,32

quad:
		sta a
		sty y
		sta quad0+1
		lda #0
		asl quad0+1
		rol
		asl quad0+1
		rol
		asl quad0+1
		rol
		tax
		lda quad0+1
		clc
		adc #<chrset
		sta quad0+1
		txa
		adc #>chrset
		sta quad0+2
		ldx #7
quad0:
		lda $ffff,x
		sta charbuf,x
		dex
		bpl quad0
		lda #0
		sta x
quad1:
		lda #4
		sta w
		lda a
		cmp #10
		bcc quad2
		lda #1
		sta w
quad2:
		ldx x
		lda #0
		asl charbuf,x
		rol
		asl charbuf,x
		rol
		asl charbuf+1,x
		rol
		asl charbuf+1,x
		rol
		tax
		lda quadchr,x
		sta screen,y
		lda c1
		sta screen+$d400,y
		iny
		dec w
		bne quad2
		inc x
		inc x
		lda x
		cmp #8
		bcs quad3
		lda y
		clc
		adc #40
		sta y
		tay
		jmp quad1
quad3:
		tya
		clc
		adc #136
		tay
		lda a
		rts

chrset:
		.byte %00011100
		.byte %00100010
		.byte %00100010
		.byte %00100010
		.byte %00100010
		.byte %00100010
		.byte %00011100
		.byte %00000000

		.byte %00001000
		.byte %00011000
		.byte %00001000
		.byte %00001000
		.byte %00001000
		.byte %00001000
		.byte %00011100
		.byte %00000000

		.byte %00011100
		.byte %00100010
		.byte %00000010
		.byte %00011100
		.byte %00100000
		.byte %00100000
		.byte %00111110
		.byte %00000000

		.byte %00011100
		.byte %00100010
		.byte %00000010
		.byte %00001100
		.byte %00000010
		.byte %00100010
		.byte %00011100
		.byte %00000000

		.byte %00100100
		.byte %00100100
		.byte %00100100
		.byte %00111110
		.byte %00000100
		.byte %00000100
		.byte %00000100
		.byte %00000000

		.byte %00111110
		.byte %00100000
		.byte %00100000
		.byte %00111100
		.byte %00000010
		.byte %00000010
		.byte %00111100
		.byte %00000000

		.byte %00011100
		.byte %00100010
		.byte %00100000
		.byte %00111100
		.byte %00100010
		.byte %00100010
		.byte %00011100
		.byte %00000000

		.byte %00111110
		.byte %00000010
		.byte %00000010
		.byte %00000100
		.byte %00001000
		.byte %00010000
		.byte %00010000
		.byte %00000000

		.byte %00011100
		.byte %00100010
		.byte %00100010
		.byte %00011100
		.byte %00100010
		.byte %00100010
		.byte %00011100
		.byte %00000000

		.byte %00011100
		.byte %00100010
		.byte %00100010
		.byte %00011110
		.byte %00000010
		.byte %00100010
		.byte %00011100
		.byte %00000000

		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %00000000

		.byte %00000000
		.byte %01000000
		.byte %00000000
		.byte %00000000
		.byte %00000000
		.byte %01000000
		.byte %00000000
		.byte %00000000
