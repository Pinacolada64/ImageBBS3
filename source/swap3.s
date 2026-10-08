.pseudopc protostart {
.namespace swap3 {

hc000:
		jmp read0
hc003:
		jmp newuser
hc006:
		jmp relread
hc009:
		jmp convdate
hc00c:
		jmp copyrite
hc00f:
		jmp read_interface_byte
hc012:
		jmp write_interface_byte

// jump table routines

outastr:
		lda #0
		.byte $2c
dskin:
		lda #2
		.byte $2c
usevar:
		lda #29
		.byte $2c
putvar:
		lda #30
		.byte $2c
zero:
		lda #31
		.byte $2c
minusone:
		lda #32
		.byte $2c
prtvar0:
		lda #46
		.byte $2c
output:
		lda #55
		jmp usetbl1

// file read routines

//* unabortable for new user
newuser:
		lda #1
		sta readmode
		jmp read0

relread:
		lda #$bf
		sta read1b+1

//* main file reader
read0:
		cpx #$00
		beq read0a
		stx filenum
read0a:
		cpy #0
		beq readf
		jmp movie
readf:
		ldx filenum
		ldy #0
		jsr dskin
		lda $90
		sta dstat
		lda index
		beq read1
		lda buf2
		cmp #'^'
		beq read2
read1:
		jsr zero
		lda index
		cmp #80
		beq read1a
		jsr minusone
read1a:
		ldx #var_lp_float
		jsr putvar
		jsr zero
		ldx #var_rc_float
		jsr putvar
		jsr outastr
		lda dstat
read1b:
		and #$ff
		bne read2
		lda readmode
		bne readf
		ldx #var_rc_float
		jsr usevar
		lda varbuf
		beq readf
read2:
		lda #$ff
		sta read1b+1
		lda #0
		sta readmode
		rts

// movie view

movie:
		sty movdly
movie1:
		ldx filenum
		jsr chkin
		jsr chrin
		sta $fe
		jsr readst
		pha
		jsr clrchn
		ldx movdly
		ldy#0
dl1:
		dey
		bne dl1
		dex
		bne dl1
		jsr output
		pla
		ldx chat
		bne movie2
		tax
		beq movie1
movie2:
		rts
movdly:
		.byte 0

// print copyright message

copyrite:
		lda outastrp+1
		sta jmptbl
		lda outastrp+2
		sta jmptbl+1

		ldy #copymsg_end - copymsg - 1
loop:
		lda copymsg,y
		sta buffer,y
		dey
		bpl loop

		lda #copymsg_end-copymsg
		sta varbuf
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2

		ldx #var_an_string
		jsr putvar

		ldx #var_an_string
		jmp prtvar0

copymsg:
		.byte function_key_6, british_pound, 95
		.text "07IMAGE BBS 64 V" + version_number
		.byte function_key_6
copymsg_end:

mult3:
		tya
		sta mult3a+1
		asl
		clc
mult3a:
		adc #$00
		tay
		rts

//* convert date to string *
convdate:
		jsr timezone
		lda datebuf
		ldy #0
		and #15
		beq conv00
		cmp #8
		bcs conv00
		tay
conv00:
		jsr mult3
		ldx #0
convdate_loop1:
		lda daytbl,y
		sta date1,x
		iny
		inx
		cpx #3
		bcc convdate_loop1
		lda datebuf+4
		and #15
		ldx datebuf+3
		cpx #'0'
		beq conv01
		clc
		adc #10
conv01:
		ldy #13
		cmp #0
		beq conv02
		cmp #13
		bcs conv02
		tay
		dey
conv02:
		jsr mult3
		ldx #4
convdate_loop2:
		lda montbl,y
		sta date1,x
		iny
		inx
		cpx #7
		bcc convdate_loop2
		lda datebuf+1
		sta date1+14
		lda datebuf+2
		sta date1+15
		lda datebuf+5
		sta date1+8
		lda datebuf+6
		sta date1+9
		lda datebuf+9
		sta date1+20
		lda datebuf+10
		sta date1+21
		lda datebuf+7
		and #'1'
		sta date1+17
		lda datebuf+8
		sta date1+18
		ldx #17
		jsr convert6
		ldx #8
		jsr convert6
		lda datebuf+7
		ldx #'P'
		cmp #'8'
		bcs convert5
		ldx #'A'
convert5:
		stx date1+23
		rts

convert6:
		lda date1,x
		cmp #'0'
		bne convert7
		lda #' '
		sta date1,x
convert7:
		rts

atob:
		lda datebuf,y
		and #$0f
		tax
		iny
atob0:
		lda datebuf,y
		and #$0f
		iny
		cpx #0
		beq atob2
atob1:
		clc
		adc #10
		dex
		bne atob1
atob2:
		rts

btoa:
		ldx #0
btoa1:
		cmp #10
		bcc btoa2
		sbc #10
		inx
		bne btoa1
btoa2:
		pha
		txa
		jsr btoa3
		pla
btoa3:
		ora #$30
		sta datebuf,y
		iny
		rts

htom:
		cmp #12
		beq htom1
		cmp #92
		bne htom2
htom1:
		sec
		sbc #12
htom2:
		cmp #80
		bcc htom3
		sbc #68
htom3:
		rts

mtoh:
		cmp #12
		bcc mtoh1
		clc
		adc #68
mtoh1:
		cmp #0
		beq mtoh2
		cmp #80
		bne mtoh3
mtoh2:
		clc
		adc #12
mtoh3:
		rts

dday:
		.byte 0
dyear:
		.byte 0
dmonth:
		.byte 0
ddate:
		.byte 0
dhour:
		.byte 0
dmin:
		.byte 0

timezone:
		ldx #0
		ldy #0
		jsr atob0
		sta dday
		jsr atob
		sta dyear
		jsr atob
		sta dmonth
		jsr atob
		sta ddate
		jsr atob
		jsr htom
		sta dhour
		jsr atob
		sec
		sbc tzonem
		bcs tz01
		adc #60
		clc
tz01:
		sta dmin
		lda dhour
		sbc tzoneh
		bcs tz02
		adc #24
		clc
tz02:
		sta dhour
		bcs tz06
		ldx dday
		dex
		bne tz03
		ldx #7
tz03:
		stx dday
		ldx ddate
		dex
		bne tz05
		ldx dmonth
		dex
		bne tz04
		dec dyear
		ldx #12
tz04:
		stx dmonth
		lda daysofm-1,x
		tax
tz05:
		stx ddate

tz06:
		lda dmin
		clc
		adc uzonem
		cmp #60
		bcc tz07
		sbc #60
		sec
tz07:
		sta dmin
		lda dhour
		adc uzoneh
		cmp #24
		bcc tz08
		sbc #24
		sec
tz08:
		sta dhour
		bcc tz11
		ldx dday
		inx
		cpx #8
		bcc tz09
		ldx #1
tz09:
		stx dday
		lda ddate
		ldx dmonth
		cmp daysofm-1,x
		bcc tz10
		lda #0
		inx
		cpx #13
		bcc tz10
		ldx #1
		inc dyear
tz10:
		stx dmonth
		tax
		inx
		stx ddate

tz11:
		ldy #0
		lda dday
		jsr btoa3
		lda dyear
		jsr btoa
		lda dmonth
		jsr btoa
		lda ddate
		jsr btoa
		lda dhour
		jsr mtoh
		jsr btoa
		lda dmin
		jsr btoa
		rts

read_interface_byte:
		txa
		asl
		cpx #interface_byte_table_end - interface_byte_table
		bcc interface_byte_out_of_range

		lda interface_byte_table,x
		sta read_interface_byte_load+1
		lda interface_byte_table+1,x
		sta read_interface_byte_load+2
read_interface_byte_load:
		lda $ffff
		cpy #0
		bne read_interface_byte_done
		tay
		ldx #var_a_integer
		jsr putvar
read_interface_byte_done:
		rts

interface_byte_out_of_range:
		lda #0
		rts

write_interface_byte:
		txa
		asl
		cpx #interface_byte_table_end - interface_byte_table
		bcc interface_byte_out_of_range

		lda interface_byte_table,x
		sta write_interface_byte_load+1
		lda interface_byte_table+1,x
		sta write_interface_byte_load+2
write_interface_byte_load:
		sty $ffff
		rts

interface_byte_table:
		.word llen    // input line length
//		.word local   // local-only output flag
//		.word mci     // enable MCI in output
interface_byte_table_end:
}
}
