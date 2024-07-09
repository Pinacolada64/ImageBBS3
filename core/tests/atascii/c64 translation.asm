tblatc = $1480 ; $ 80/128 bytes
tblcta = $1500 ; $100/256 bytes
tblcta1= $1600 ; $ 20/ 32 bytes
tblcta2= $1620 ; $ 20/ 32 bytes
tblcta3= $1640 ; $ 20/ 32 bytes

.org tblatc

; "ascii -> commodore" translation table

tr1:
	; $00-$07
	.byte $00,$00,$02,$00,$04,$00,$00,$00
	; $08-$0f
	.byte $14,$09,$00,$00,$93,$0d,$0e,$0f
	; $10-$1f
	.byte 0,$11,0,$13,20,$15,$16,$17,$18,$19,0,27,0,0,0,0
	; $20-$2f
	.text " !{34}#$%&'()*+,-./"
	; $30-$3f
	.text "0123456789:;<=>?"
	; $40-$5b
	.text "@ABCDEFGHIJKLMNOPQRSTUVWXYZ["
	.byte $5c
	; $5d-$5f
	.text "]^_"
	; $60
	.byte 0
	; $61-$80
	.text "abcdefghijklmnopqrstuvwxyz"
	; extra bytes? $81-$85
	.byte 0,0,0,0,20

; PETSCII -> ASCII translation
; tblcta: $100 bytes
tr2:
	; $00-$07
	.byte $00, $01, $02, $03, $04, $05, $06, $07
	; $08-$0f
	.byte $08, $09, $0a, $0b, $0c, $0d, $00, $0f
	; $10-17
	.byte $10, $11, $12, $13, $08, $15, $16, $17
	; $18-$1f
	.byte $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
	; $20-$2f
	.text " !"
	.byte 34
	.text "#$%&'()*+,-./"
	; $30-$3f
	.text "0123456789:;<=>?"
	; $40-$5f
	.text "@abcdefghijklmnopqrstuvwxyz[\]^_"
	; $60-$7f
	.text "-ABCDEFGHIJKLMNOPQRSTUVWXYZ*-!**"
	; $80-$9f
	.byte 0,129,0,0,0,0,0,0,0,0,0,0,0,$d,0,0
	; $a0-$af
	.byte 0,145,146,12,0,149,150,151,152,153,154,155,156,157,158,159
	; $b0-$bf
	.text " !---!*!-*!****-"
	; $c0-$cf
	.text "****!!!---******"
	; $d0-$ef
	.text "-ABCDEFGHIJKLMNOPQRSTUVWXYZ*!!**"
	; $f0-$ff
	.text " !---!*!-*!****-"
; extra bytes?
;	.text "****!!!---******"
