#import "equat.s"

* =  protostart "rs232.prg"

ml:
		cpx #2
		bcs ml3
		lda rslow,x
		sta ml1+1
		lda rshigh,x
		sta ml1+2
		ldy #0
		ldx #3
ml1:
		lda rs232a,y
ml2:
		sta rs232,y
		iny
		bne ml1
		inc ml1+2
		inc ml2+2
		dex
		bne ml1
ml3:
		jmp rs232

rslow:
		.byte <rs232a, <rs232b
rshigh:
		.byte >rs232a, >rs232b

rs232a:
		.import c64 "rs232_user.prg"
rs232b:
		.import c64 "rs232_swift.prg"
