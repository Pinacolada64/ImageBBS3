orig $c000
; FIXME: I believe there is a bug with strings and crsr-left/crsr-right
; am fairly certain that a file I was looking at showed [Crsr Right] when it was actually a [Crsr Left]

;
; **** zp absolute adresses ****
;
a61 = $61 ; start of variable buffer
a62 = $62
a63 = $63
usetbl1 = $cd03	; .a: & routine to use
		; .x: param1?
		; .y: param2?
;
; **** user labels ****
;
buf2 = $ce27
buffer = $ce77
;
; **** predefined labels ****
;
rom_readst = $ffb7
rom_chkin = $ffc6
rom_getin = $ffe4

	jmp jc01d
	byte $06
ac004:
	byte $00
ac005:
	byte $00
ac006:
	byte $00
ac007:
	byte $00
ac008:
	byte $00
ac009:
	byte $00
ac00a:
	byte $00 ; rq (abort) status?
ac00b:
	byte $00
ac00c:
	byte $00
ac00d:
	byte $00
ac00e:
	byte $00
ac00f:
	byte $00
ac010:
	byte $00
ac011:
	byte $00

; [K]ML Tail:[KK]
pc012:
	ascii $8b, $cd, $cc, " ", $d4, "ail:", $8b
	ascii $8b
jc01d:
	cpx #$ff
	bne bc02d
	jsr sca36
	lda #$06
	sta a62
	ldx #$1e
	jmp putvar

bc02d:
	stx ac004
	lda #$08
	sta ac011
	tya
	beq bc043
	sec
	sbc #$08
	and #$fc
	clc
	ror
	ror
	sta ac011
bc043:
	lda #$00
	sta ac007
	sta ac00a
	sta ac010
	sta ac00d
	sta ac00e
	sta ac00f
	ldx #$02
	jsr rom_chkin ;$ffc6 - open channel for input
	jsr sc87c
	sta ac008
	jsr sc87c
	sta ac009
	lda ac009
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda hexnums,y
	sta ac86e
	lda ac009
	and #$0f
	tay
	lda hexnums,y
	sta ac86f
	lda ac008
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda hexnums,y
	sta ac870
	lda ac008
	and #$0f
	tay
	lda hexnums,y
	sta ac871
	lda #<pc85a
	sta a62
	lda #>pc85a
	sta a63
	lda #$1a
	sta a61
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
	lda ac008
	cmp #$01
	bne bc0c7
	lda ac009
	cmp #$08
	bne bc0c7
	jmp jc0fd

bc0c7:
	lda ac008
	cmp #$01
	bne bc0d8
	lda ac009
	cmp #$1c
	bne bc0d8
	jmp jc0fd

bc0d8:
	lda ac008
	cmp #$01
	bne bc0e9
	lda ac009
	cmp #$40
	bne bc0e9
	jmp jc0fd

bc0e9:
	lda ac008
	cmp #$01
	bne bc0fa
	lda ac009
	cmp #$04
	bne bc0fa
	jmp jc0fd

bc0fa:
	jmp jc8bf

jc0fd:
	lda ac009
	pha
	lda ac008
	pha
	ldx #$10
	jsr sca2f
	ldx #$1e	; a%
	jsr usevar
	lda a62
	beq bc139
	lda #$01
	sta ac010
	ldx #$12
	jsr sca2f
	ldx #$1e	; a%
	jsr usevar
	lda a62
	beq bc139
	ldx #$13
	jsr sca2f
	ldx #$1e	; a%
	jsr usevar
	lda a62
	beq bc139
	lda #$00
	sta ac010
bc139:
	lda ac010
	ora ac004
	sta ac010
jc142:
	lda ac00a
	beq bc14c
	pla
	pla
	jmp jca11

bc14c:
	jsr sc87c
	sta ac008
	jsr sc87c
	sta ac009
	cmp #$00
	bne bc1a4
	lda ac008
	cmp #$00
	bne bc1a4
	lda ac00a
	beq bc16d
	pla
	pla
	jmp jca11

bc16d:
	lda #<pc012
	sta a62
	lda #>pc012
	sta a63
	lda #$0b
	sta a61
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
	pla
	clc
	adc ac00d
	sta ac008
	pla
	adc ac00e
	sta ac009
	lda ac008
	sec
	sbc #$02
	sta ac008
	lda ac009
	sbc #$00
	sta ac009
	jmp jc8bf

bc1a4:
	jsr sc87c
	sta ac008
	jsr sc87c
	sta ac009
	lda ac008
	sta a62
	lda ac009
	sta a61
	ldx #$1e	; a%
	jsr putvar
	lda #<pc875
	sta a62
	lda #>pc875
	sta a63
	lda #$07
	sta a61
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
jc1d3:
	jsr sc87c
	sta ac004
	cmp #$00
	bne bc1fe
	lda #$8b
	sta buf2
	lda #<p2701
	sta a61
	lda #>p2701
	sta a62
	lda #$ce
	sta a63
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
	lda #$00
	sta ac007
	jmp jc142

bc1fe:
	and #$80
	bne bc205
	jmp jc29d

bc205:
	lda ac007
	beq bc20d
	jmp jc29d

bc20d:
	lda ac004
	cmp #$ce
	bne bc227
	jsr sc87c
	sta ac004
	lda #<pc82a
	sta afb
	lda #>pc82a
	sta afc
	ldx #$02
	jmp jc248

bc227:
	cmp #$fe
	bne bc23e
	jsr sc87c
	sta ac004
	lda #<pc76b
	sta afb
	lda #>pc76b
	sta afc
	ldx #$02
	jmp jc248

bc23e:
	lda #<pc578
	sta afb
	lda #>pc578
	sta afc
	ldx #$80
jc248:
	cpx ac004
	bne bc250
	jmp jc26f

bc250:
	inc afb
	lda afb
	bne bc258
	inc afc
bc258:
	ldy #$00
	lda (pfb),y
	and #$80
	bne bc26b
	inc afb
	lda afb
	bne bc258
	inc afc
	jmp bc258

bc26b:
	inx
	jmp jc248

jc26f:
	ldy #$00
	lda (pfb),y
	and #$7f
	sta buf2,y
	iny
jc279:
	lda (pfb),y
	and #$80
	bne bc288
	lda (pfb),y
	sta buf2,y
	iny
	jmp jc279

bc288:
	sty a61
	lda #<buf2
	sta a62
	lda #>buf2
	sta a63
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
	jmp jc1d3

jc29d:
	jsr sc2a3
	jmp bc288

sc2a3:
	lda ac004
	sta buf2
	cmp #$22
	bne bc2b8
	lda ac007
	eor #$01
	sta ac007
	jmp jc336

bc2b8:
	cmp #$5c
	bne bc2c4
	lda #$5c
	sta ace28
	ldy #$02
	rts

bc2c4:
	ldy #$00
bc2c6:
	cmp fc508,y
	beq bc2d3
	iny
	cpy #$38
	bne bc2c6
	jmp jc318

bc2d3:
	lda ac010
	beq bc305
	lda #<pc34c
	sta afb
	lda #>pc34c
	sta afc
	tya
	tax
jc2e2:
	ldy #$00
	cpx #$00
	beq bc2fa
bc2e8:
	inc afb
	lda afb
	bne bc2f0
	inc afc
bc2f0:
	lda (pfb),y
	cmp #$5b
	bne bc2e8
	dex
	jmp jc2e2

bc2fa:
	lda (pfb),y
	sta buf2,y
	iny
	cmp #$5d
	bne bc2fa
	rts

bc305:
	lda fc540,y
	sta ace28
	lda #$12
	sta buf2
	lda #$92
	sta ace29
	ldy #$03
	rts

jc318:
	cmp #$1c
	bne jc336
	lda ac010
	bne bc339
	lda #<p5c12
	sta buf2
	lda #>p5c12
	sta ace28
	sta ace29
	lda #$92
	sta ace2a
	ldy #$04
	rts

jc336:
	ldy #$01
	rts

bc339:
	ldy #$00
bc33b:
	lda fc347,y
	sta buf2,y
	iny
	cpy #$05
	bne bc33b
	rts

fc347:
	ascii "[", $d2, "ed]"
pc34c:
	ascii "[", $c3, "trl-a]"
	ascii "[", $c3, "trl-b]"
	ascii "[", $c3, "trl-c]"
	ascii "[", $c3, "trl-d]"
	ascii "[", $d7, "hite]"
	ascii "[", $c3, "trl-f]"
	ascii "[", $c3, "trl-g]"
	ascii "[", $c3, "trl-h]"
	ascii "[", $c3, "trl-i]"
	ascii "[", $c3, "trl-j]"
	ascii "[", $c3, "trl-k]"
	ascii "[", $c3, "trl-l]"
	ascii "[", $d2, "eturn]"
	ascii "[", $c3, "trl-n]"
	ascii "[", $c3, "trl-o]"
	ascii "[", $c3, "trl-p]"
	ascii "[", $c3, "rsr ", $c4, "wn]"
	ascii "[", $d2, "ev ", $cf, "n]"
	ascii "[", $c8, "ome]"
	ascii "[", $c2, "ackspace]"
	ascii "[", $c3, "trl-u]"
	ascii "[", $c3, "trl-v]"
	ascii "[", $c3, "trl-w]"
	ascii "[", $c3, "trl-x]"
	ascii "[", $c3, "trl-y]"
	ascii "[", $c3, "trl-z]"
	; function keys:
	ascii "[", $c6, "1]"
	ascii "[", $c6, "3]"
	ascii "[", $c6, "5]"
	ascii "[", $c6, "7]"
	ascii "[", $c6, "2]"
	ascii "[", $c6, "4]"
	ascii "[", $c6, "6]"
	ascii "[", $c6, "8]"
	ascii "[", $c3, "rsr ", $d5, "p]"
	ascii "[", $c3, "rsr ", $cc, "eft]"
	ascii "[", $c3, "rsr ", $d2, "ight]"
	ascii "[", $c3, "trl-", $ce, "]"
	ascii "[", $c2, "lack]"
	ascii "[", $c3, "yan]"
	ascii "[", $d0, "urple]"
	ascii "[", $c7, "reen]"
	ascii "[", $c2, "lue]"
	ascii "[", $d9, "ellow]"
	ascii "[", $d2, "ev ", $cf, "ff]"
	ascii "[", $cf, "range]"
	ascii "[", $c2, "rown]"
	ascii "[", $cc, "t. ", $d2, "ed]"
	ascii "[", $c4, "ark ", $c7, "ray]"
	ascii "[", $cd, "ed. ", $c7, "ray]"
	ascii "[", $cc, "t. ", $c7, "reen]"
	ascii "[", $cc, "t. ", $c2, "lue]"
	ascii "[", $cc, "t. ", $c7, "ray]"
	ascii "[", $c3, "lear/", $c8, "ome]"
	ascii "[", $c3, "trl-@]"
	ascii "[", $d3, "hift-", $d2, "eturn]"
fc508:
	ascii $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a
	ascii $0b, $0c, $0d, $0e, $0f, $10, $11, $12, $13, $14
	ascii $15, $16, $17, $18, $19, $1a, $85, $86, $87, $88
	ascii $89, $8a, $8b, $8c, $91, $1d, $9d, $8e, $90, $9f
	ascii $9c, $1e, $1f, $9e, $92, $81, $95, $96, $97, $98
	ascii $99, $9a, $9b, $93, $00, $8d
fc540:
	ascii "abcdefghijklmnopqrstuvwxyz"
	ascii $c5, $c6, $c7, $c8
	ascii $c9, $ca, $cb, $cc, $d1, "]", $dd, $ce, $d0, $df
	ascii $dc, "^_", $a6, $d2, $c1, $d5, $d6, $d7, $d8
	ascii $d9, $da, $db, $d3, "@", $cd

	; c64 BASIC keywords

pc578:
	; end for next
	ascii $c5, "nd", $c6, "or", $ce, "ext"
	; data input#
	ascii $c4, "ata", $c9, "nput#"
	; input dim read
	ascii $c9, "nput", $c4, "im", $d2, "ead"
	; let goto
	ascii $cc, "et", $c7, "oto"
	; run if restore
	ascii $d2, "un", $c9, "f", $d2, "estore"
	; gosub return
	ascii $c7, "osub", $d2, "eturn"
	; rem stop on
	ascii $d2, "em", $d3, "top", $cf, "n"
	; wait load
	ascii $d7, "ait", $cc, "oad", $d3
	; save verify def
	ascii "ave", $d6, "erify", $c4, "ef"
	; poke print#
	ascii $d0, "oke", $d0, "rint#"
	; print, cont
	ascii $d0, "rint", $c3, "ont"
	; list clr cmd
	ascii $cc, "ist", $c3, "lr", $c3, "md"
	; sys open close
	ascii $d3, "ys", $cf, "pen", $c3, "lose"
	; let new tab(
	ascii $c7, "et", $ce, "ew", $d4, "ab("
	; to fn spc(
	ascii $d4, "o", $c6, "n", $d3, "pc("
	; then not step
	ascii $d4, "hen", $ce, "ot", $d3, "tep"
	; ??? and
	ascii $ab, $ad, $aa, $af, $de, $c1, "nd"
	; ??? sgn int
	ascii $cf, "r", $be, $bd, $bc, $d3, "gn", $c9, "nt"
	; abs usr fre
	ascii $c1, "bs", $d5, "sr", $c6, "re"
	; pos sqr rnd
	ascii $d0, "os", $d3, "qr", $d2, "nd"
	; log exp cos sin
	ascii $cc, "og", $c5, "xp", $c3, "os", $d3, "in"
	; tan atn peek
	ascii $d4, "an", $c1, "tn", $d0, "eek"
	; len str$ val
	ascii $cc, "en", $d3, "tr$", $d6, "al"
	; asc chr$ left$
	ascii $c1, "sc", $c3, "hr$", $cc, "eft$"
	; right$ mid$
	ascii $d2, "ight$", $cd, "id$"

; c-128 tokens
	; go rgr rclr
	ascii $c7, "o", $d2, "gr", $d2, "clr"
	; joy rdot
	ascii $ce, $ca, "oy", $d2, "dot"
	; dec hex$, err
	ascii $c4, "ec", $c8, "ex$", $c5, "rr$"
	; instr, else
	ascii $c9, "nstr", $c5, "lse"
	; resume trap
	ascii $d2, "esume", $d4, "rap"
	; tron troff
	ascii $d4, "ron", $d4, "roff", $d3
	; sound vol auto
	ascii "ound", $d6, "ol", $c1, "uto"
	; pudef, graphic
	ascii $d0, "udef", $c7, "raphic"
	; paint char
	ascii $d0, "aint", $c3, "har"
	; box circle
	ascii $c2, "ox", $c3, "ircle"
	; gshape sshape
	ascii $c7, "shape", $d3, "shape"
	; draw locate
	ascii $c4, "raw", $cc, "ocate"
	; color scnclr
	ascii $c3, "olor", $d3, "cnclr"
	; scale help
	ascii $d3, "cale", $c8, "elp"
	; do loop
	ascii $c4, "o", $cc, "oop"
	; exit directory
	ascii $c5, "xit", $c4, "irectory"
	; dsave dload
	ascii $c4, "save", $c4, "load"
	; header scratch
	ascii $c8, "eader", $d3, "cratch"
	; collect
	ascii $c3, "ollect"
	; copy rename
	ascii $c3, "opy", $d2, "ename"
	; backup delete
	ascii $c2, "ackup", $c4, "elete"
	; renumber
	ascii $d2, "enumber"
	; key monitor
	ascii $cb, "ey", $cd, "onitor"
	; using until
	ascii $d5, "sing", $d5, "ntil"
	; while ??
	ascii $d7, "hile", $fe, "?"
pc76b:
	; bank filter
	ascii $c2, "ank", $c6, "ilter"
	; play tempo
	ascii $d0, "lay", $d4, "empo"
	; movspr sprite
	ascii $cd, "ovspr", $d3, "prite"
	; sprcolor, rreg
	ascii $d3, "prcolor", $d2, "reg"
	; envelope
	ascii $c5, "nvelope"
	; sleep, catalog
	ascii $d3, "leep", $c3, "atalog"
	; dopen, append
	ascii $c4, "open", $c1, "ppend"
	; close
	ascii $c4, "close"
	; save load
	ascii $c2, "save", $c2, "load"
	; record, concat
	ascii $d2, "ecord", $c3, "oncat"
	; dverify
	ascii $c4, "verify"
	; dclear, sprsav
	ascii $c4, "clear", $d3, "prsav"
	; collision
	ascii $c3, "ollision"
	; begin, bend
	ascii $c2, "egin", $c2, "end"
	; window, boot
	ascii $d7, "indow", $c2, "oot"
	; width sprdef
	ascii $d7, "idth", $d3, "prdef"
	; quit stash
	ascii $d1, "uit", $d3, "tash", $ff
	; fetch swap
	ascii $c6, "etch", $ff, $d3, "wap"
	; off fast slow
	ascii $cf, "ff", $c6, "ast", $d3, "low"
pc82a:
	; pot bump pen
	ascii $d0, "ot", $c2, "ump", $d0, "en"
	; rsppos rsprite
	ascii $d2, "sppos", $d2, "sprite"
	; rspcolor
	ascii $d2, "spcolor"
	; xor, window
	ascii $d8, "or", $d2, "window"
	; pointer
	ascii $d0, "ointer"

pc85a:
	ascii $93, "{pound}q0", $8b, $cc, "oad "
	ascii $c1, "ddress: $"
ac86e:
	ascii "0"
ac86f:
	ascii "0"
ac870:
	ascii "0"
ac871:
	ascii "0", $8b, $8b, $00
pc875:
	ascii "{pound}#0{pound}%a "

sc87c:
	jsr rom_getin ;$ffe4 - get a byte from channel
	pha
	jsr rom_readst ;$ffb7 - read i/o status byte
	and #$40
	beq bc88c
	lda #$ff
	sta ac00a
bc88c:
	ldx #$1d	; tr%
	jsr usevar
	lda a62
	bne bc89a
	lda #$ff
	sta ac00a
bc89a:
	inc ac00d
	lda ac00d
	bne bc8ad
	inc ac00e
	lda ac00e
	bne bc8ad
	inc ac00f
bc8ad:
	pla
	rts

hexnums:
	ascii "0123456789"
	ascii $c1, $c2, $c3, $c4, $c5, $c6

jc8bf:
	lda #$00
	sta ac005
	sta ac006
	sta ac010
	lda #<buffer
	sta ac00b
	lda #>buffer
	sta ac00c
	lda ac009
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda hexnums,y
	sta buf2
	lda ac009
	and #$0f
	tay
	lda hexnums,y
	sta ace28
	lda ac008
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda hexnums,y
	sta ace29
	lda ac008
	and #$0f
	tay
	lda hexnums,y
	sta ace2a
	lda #<p203a
	sta ace2b
	lda #>p203a
	sta ace2c
	lda #<buf2
	sta a62
	lda #>buf2
	sta a63
	lda #$06
	sta a61
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
jc92c:
	lda ac00a
	beq bc941
	lda #$20
	sta ac004
	lda #$20
	sta buf2
	sta ace28
	jmp jc961

bc941:
	jsr sc87c
	sta ac004
	and #$f0
	clc
	ror
	ror
	ror
	ror
	tay
	lda hexnums,y
	sta buf2
	lda ac004
	and #$0f
	tay
	lda hexnums,y
	sta ace28
jc961:
	lda #$20
	sta ace29
	lda #<p2703
	sta a61
	lda #>p2703
	sta a62
	lda #$ce
	sta a63
	ldx #$01	; a$
	jsr putvar
	jsr sca3b
	jsr sc2a3
	sty ac004
	lda ac00b
	sta afb
	lda ac00c
	sta afc
	ldy #$00
bc98c:
	lda buf2,y
	sta (pfb),y
	iny
	cpy ac004
	bne bc98c
	lda ac00b
	clc
	adc ac004
	sta ac00b
	lda ac00c
	adc #$00
	sta ac00c
	lda ac006
	clc
	adc ac004
	sta ac006
	inc ac005
	lda ac005
	cmp ac011
	beq bc9c1
	jmp jc92c

bc9c1:
	lda ac008
	clc
	adc ac011
	sta ac008
	lda ac009
	adc #$00
	sta ac009
	jsr sc9e1
	lda ac00a
	bne bc9de
	jmp jc8bf

bc9de:
	jmp jca11

sc9e1:
	lda #<pca10
	sta a62
	lda #>pca10
	sta a63
	lda #$01
	sta a61
	ldx #$01
	jsr jca2a
	jsr sca3b
	lda #<buffer
	sta a62
	lda #>buffer
	sta a63
	ldy ac006
	lda #$8b
	sta buffer,y
	iny
	sty a61
	ldx #$01
	jsr jca2a
	jmp sca3b

jca11 = pca10 + $01
pca10:
	jsr e0ead
	cpy #$85
	byte $62
	lda ac00f
	sta a61
	ldx #$1e
	jmp jca2a

sca20:
	lda #$1d
	jmp ecd03

	lda #$16
	jmp ecd03

jca2a:
	lda #$1e
	jmp ecd03

sca2f:
	lda #$34
	ldy #$03
	jmp ecd03

sca36:
	lda #$1f
	jmp ecd03

sca3b:
	lda #$00
	jsr ecd03
	ldx #$11
	jsr sca20
	lda a61
	ora ac00a
	sta ac00a
	rts

	ascii "01/09/91  5:00p"
	byte $0d
	ascii $c3, "opr.1991 ", $ce, "ew ", $c9, "mage"
