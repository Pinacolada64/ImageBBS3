getmod:
		jsr getmdm
		sta $fe
		lda flag_cht_addr
		and #flag_cht_r_mask
		beq getmod0
		lda #0
		sta $fe
		rts
getmod0:
		lda flag_asc_addr
		and #flag_asc_l_mask
		beq getmod1
		ldx $fe
		lda tblatc,x
		sta $fe
getmod1:
		lda $fe
		cmp #0
		rts

outmodh:
		ldx interm
		bne outmodh1
		jsr outm
		lda #' '
		jsr outm
outmodh1:
		lda #dish
		jmp outm

outmod:
		lda flag_asc_addr
		and #flag_asc_l_mask
		bne outmod0
		lda $fe
		jmp outm
outmod0:
		lda flag_ans_addr
		and #flag_ans_r_mask
		tax
		lda $fe
		and #$1f
		tay
		lda $fe
		cpx #0
		beq outmod0e
		cmp #096
		bcc outmod0e
		cmp #128
		bcc outmod0a
		cmp #160
		bcc outmod0e
		cmp #192
		bcc outmod0d
		cmp #224
		bcs outmod0e
outmod0a:
		lda mupcase
		bne outmod0c
		lda tblcta2,y
		bne outmod1
outmod0c:
		lda tblcta3,y
		bne outmod1
outmod0d:
		lda tblcta1,y
		bne outmod1
outmod0e:
		tax
		lda tblcta,x
		beq outmod3
outmod1:
		pha
		and #$7f
		cmp #32
		pla
		bcc outmod1a
		jmp outm
outmod1a:
		pha
		lda flag_ans_addr
		and #flag_ans_l_mask
		tax
		pla
		cmp #dish
		beq outmodh
		cmp #13
		beq outmodm
		cmp #ascii_formfeed
		beq outmodl
		cpx #0
		beq outmod3
		cmp #cursor_up
		beq outmodup
		cmp #cursor_down
		beq outmoddn
		cmp #cursor_right
		beq outmodrt
		cmp #cursor_left
		beq outmodlf
		cmp #reverse_off
		beq outmodr0
		cmp #reverse_on
		beq outmodr1
		cmp #cursor_home
		beq outmodhm
		jsr colorchk
		bcs outmod3
		jmp outmodc
outmod3:
		rts

outmodm:
		lda interm
		bne outmodm1
		cpx #0
		beq outmodm1
		jsr outmodr0
outmodm1:
		lda flag_asc_addr
		and #flag_asc_r_mask

// TODO clean this up, can eliminate php/plp
		php
		lda #13
		plp
		beq outmodm2
		jsr outm
		lda #10
outmodm2:
		jmp outm

outmodup:
		lda #$41
		bne ansicom
outmoddn:
		lda #$42
		bne ansicom
outmodrt:
		lda #$43
		bne ansicom
outmodlf:
		lda #$44
ansicom:
		pha
		lda #27
		jsr outm
		lda #'['
		jsr outm
		pla
		jmp outm

outmodr0:
		lda #'3'
		ldx #'4'
		bne outmodr
outmodr1:
		lda #'4'
		ldx #'3'
outmodr:
		sta ansir1
		stx ansir2
		jmp ansi

outmodl:
		cpx #0
		bne outmodl1
		jmp outm
outmodl1:
		lda #'2'
		jsr ansicom
		.encoding "ascii"
		lda #'J'
		.encoding "petscii_mixed"
		jmp outm

outmodhm:
		lda #'1'
		jsr ansicom
		lda #';'
		jsr outm
		lda #'1'
		jsr outm
		.encoding "ascii"
		lda #'H'
		.encoding "petscii_mixed"
		jmp outm

outmodc:
		ldx #15
outmodc2:
		cmp colors,x
		beq outmodc3
		dex
		bne outmodc2
outmodc3:
		lda ansiclrs,x
		sta ansicol
		lda ansiints,x
		sta ansiint
ansi:
		ldy #0
ansi1:
		tya
		pha
		lda ansibuf,y
		beq ansi2
		jsr outm
		pla
		tay
		iny
		bne ansi1
ansi2:
		pla
		rts

ansiclrs:
		.text "7716524333107247"
ansiints:
		.text "0100000100110110"
ansibuf:
		.byte 27
		.text "[0;"
ansiint:
		.text "0;"
ansir1:
		.text "3"
ansicol:
		.text "1;"
ansir2:
		.text "4"
ansibak:
		.text "0"
		.byte $6d, 0
