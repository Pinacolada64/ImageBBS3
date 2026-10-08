.encoding "petscii_mixed"

.var version = "9107098721"

#import "equat.s"

* = protostart "punter.prg"

// modem file number
.label mfile = 131
// disk file number
.label dfile = 2
// disk error channel
.label errch = 15

//on entry:

// upload - file open to #dfile
// dnload - file open to #dfile
// multiup - an$=filename,t
// multidn - nothing special

//on exit:

// upload - a%=# blocks (0 = abort)
// ........ b%=# bad blocks
// ........ rc=# bytes sent
// dnload - a%=# blocks (0 = abort)
// ........ b%=# bad blocks
// ........ rc=# bytes received
// multiup -rc=1
// multidn -an$="filename,t" ""=end
// ........ rc=(1=ok, 0=aborted)

.label xxx = 0
.label goo = 1
.label bad = 2
.label ack = 3
.label snb = 4
.label syn = 5
.label iii = 6
.label ddd = 7
.label mjz = 8
.label okm = 9

.label pbuf1= $400
.label pbuf2= $500

// start of the screen line with transfer time
.label pbuf3= $630

// index of the transfer time display
.label tcount = 16

.label codebuf = pbuf3 + 26

.label display_state = pbuf3 + 30

// start of the screen line with the good/bad counts
.label pbuf0= $658

// index of the good count display
.label gcount = 11

// index of the bad count display
.label bcount = 23

// index of the byte count display
.label ncount = 38


.label recmodem_st_got_buffer = $01
.label recmodem_st_timed_out =  $02

// Spec says 5 seconds, but we're only using one byte,
// so 4 seconds is the best whole number we can do

.label recmodem_timeout_jiffies = 240

// offsets into the block header

.label header_checksum_lsb = 0
.label header_checksum_msb = 1
.label header_clc_lsb = 2
.label header_clc_msb = 3
.label header_size_of_next_block = 4
.label header_block_number_lsb = 5
.label header_block_number_msb = 6

.label header_size = 7

// start - jump table
ml:
		lda defflag
		and #2
		inx
		beq protonum
		dex
		beq upload0 //0
		dex
		beq dnload0 //1
		dex
		beq multiup0 //2
		dex
		beq multidn0 //3
		dex
		beq setflag //4
		bne getflag

defflag:
		.byte 0
flagbyte:
		.byte 0

.label flag_relaxed =  %00000001 // use relaxed timing
.label flag_filetype = %00000010 // accept/send file type for single file transfers

versiond:
		.text version

// code accept timing
t1:
		.byte 36, 144

protonum:
		lda #0
		sta varbuf
		lda #0
		sta varbuf+1
		ldx #var_a_integer
		jmp putvar

upload0:
		jsr screen
		jsr trantype
		jsr transmit
		jmp xfer1

dnload0:
		jsr screen
		jsr rectype
		jsr recieve
		jmp xfer1

multiup0:
		cmp #0
		beq multiu0a
		jsr screen
		jmp tranname
multiu0a:
		jsr multiup
		jmp xfer1

multidn0:
		cmp #0
		beq multid0a
		jsr screen
		jmp recname
multid0a:
		jsr multidn
		jmp xfer1

setflag:
		sty defflag
		rts
getflag:
		lda defflag
		sta varbuf+1
		lda #0
		sta varbuf
		ldx #var_a_integer
		jmp putvar

// multi- send
multiup:
		jsr setup
		tsx
		stx stack
		jsr reset
		ldx #var_an_string
		jsr usevar
		lda varbuf
		beq multiup2
		ldx #iii
		jsr sendcode
		ldx #5
		jsr tenwait
		ldx #mfile
		jsr chkout
		ldy #0
multiup1:
		lda (varbuf+1),y
		jsr chrout
		iny
		cpy varbuf
		bcc multiup1
		lda #13
		jsr chrout
		jsr clrchn
multiup3:
		jsr getnumx
		bcs multiup3
		bcc multiup4
multiup2:
		ldx #iii
		jsr sendcode
		ldx #5
		jsr tenwait
		ldx #ddd
		jsr sendcode
		ldx #mjz
		jsr sendcode
multiup4:
		lda #1
		sta bytes
		lda #0
		sta bytes+1
		sta bytes+2
		rts

//multi-recieve
multidn:
		jsr setup
		tsx
		stx stack
		jsr reset
		lda #0
		sta index
multidn1:
		jsr getnumx
		bcs multidn1
		cmp #ascii_ctrl_x
		beq multidn4
		cmp #ascii_ctrl_d
		beq multidn4
		cmp #ensh
		bne multidn1
multidn2:
		jsr getnumx
		bcs multidn2
		cmp #ascii_ctrl_x
		beq multidn4
		cmp #ascii_ctrl_d
		beq multidn4
		cmp #ensh
		beq multidn2
		lda $200
		sta buffer
		lda #1
		sta index
multidn3:
		jsr getnumx
		bcs multidn3
		ldy index
		cmp #ascii_ctrl_x
		beq multidn6
		cmp #ascii_ctrl_d
		beq multidn6
		cmp #13
		beq multidn4
		cpy #18
		bcs multidn3
		sta buffer,y
		inc index
		bne multidn3
multidn4:
		lda index
		sta varbuf
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2
		ldx #var_an_string
		jsr putvar
		lda index
		beq multidn5
		ldx #okm
		jsr sendcode
multidn5:
		ldx #20
		jsr tenwait
		jmp multiup4
multidn6:
		lda #0
		sta index
		jmp multidn4
multidn7:
		jmp multiup4

// check carrier/abort

exit0:

// if the commodore key is pressed, abort the transfer

		lda $28d
		cmp #2
		beq exit_cleanup

// if carrier is lost, abort the transfer

		lda flag_dcd_addr
		and #flag_dcd_r_mask
		beq exit_cleanup

		rts

exit:

// if the commodore key is pressed, abort the transfer

		lda $28d
		cmp #2
		beq exit_cleanup

// if carrier is lost, abort the transfer

		lda flag_dcd_addr
		and #flag_dcd_r_mask
		bne ext2

// exit and abort the transfer

exit_cleanup:
		ldx stack
		txs
		ldx #xxx
		jsr sendcode
ext0:
		lda #1
		sta irqcount
		jsr nobytes
ext2:
		rts

setup:
		lda #11
		sta irqcount
		ldx #16
		ldy #3
		jsr chkmark
		lda varbuf+1
		sta oldtrans
		ldx #16
		ldy #0
		jsr chkmark
		lda defflag
		sta flagbyte
		rts

// get # bytes and exit
xfer1:
		lda #1
		sta irqcount
		ldx #16
		ldy oldtrans
		jsr chkmark
		lda blocks
		sta varbuf+1
		lda blocks+1
		sta varbuf
		ldx #var_a_integer
		jsr putvar
		lda badblks
		sta varbuf+1
		lda badblks+1
		sta varbuf
		ldx #var_b_integer
		jsr putvar
		lda bytes
		ldx bytes+1
		ldy bytes+2
		sta $64
		stx $63
		sty $62
		ldx #0
		stx $0d
		ldx #$98
		lda $62
		eor #$ff
		rol
		lda r6510
		pha
		lda #r6510_normal
		sta r6510
		lda #0
		sta $65
		// TODO get a label for this
		jsr $bc4f
		pla
		sta r6510
		lda $66
		ora #$7f
		and $62
		sta $62
		ldx #var_rc_float
		jmp putvar

// wait for code received

accept:
		sta bitpat
		lda #$00
		sta codebuf
		sta codebuf+1
		sta codebuf+2

acc1:

// clear timer for timeout check

		lda #$00
		sta jiffy

accept_loop:
		jsr getnumx
		bcs accept_no_char
acc3:

// shift code buffer

		ldx codebuf+1
		stx codebuf
		ldx codebuf+2
		stx codebuf+1
		sta codebuf+2

		jsr chkcod
		beq acc1

// calculate mask from code number

		lda #1
acc4:
		asl
		dex
		bne acc4

		and bitpat
		beq accept_loop

// expected code received

// if relaxed, don't worry about extra characters

		lda flagbyte
		and #flag_relaxed
		bne acc5

// if there is an extra character, start over
		jsr getnumx
		bcc acc3
acc5:
		lda #0
		sta $96
		rts

accept_no_char:

// check for timeout

		ldx #0
		lda flagbyte
		and #flag_relaxed
		beq accept_not_relaxed
		ldx #1
accept_not_relaxed:
		lda jiffy
		cmp t1,x
		bcc accept_loop

accept_timed_out:
		lda #1
		sta $96
		rts

// check of codebuf contains a code
// return with code in .A and bitcnt
// returns 255 if no match found

chkcod:
		ldx #syn
chkcod_loop:
		lda codebuf
		cmp char1,x
		bne chkcod_not_matched
		lda codebuf+1
		cmp char2,x
		bne chkcod_not_matched
		lda codebuf+2
		cmp char3,x
		beq chkcod_matched

chkcod_not_matched:
		dex
		bpl chkcod_loop

chkcod_matched:
		stx bitcnt
		txa
		cmp #xxx
		bne chkcode_not_xxx
// abort if xxx code received
		jmp exit_cleanup
chkcode_not_xxx:
		cmp #255
		rts

//codes.........01234567..8..9
char1:
		.byte ascii_ctrl_x
		.text "gbass"
		.byte ensh, ascii_ctrl_d, 13
		.text "o"
char2:
		.byte ascii_ctrl_x
		.text "oac/y"
		.byte ensh, ascii_ctrl_d, 10
		.text "k"
char3:
		.byte ascii_ctrl_x
		.text "odkbn"
		.byte ensh, ascii_ctrl_d, 0, 13

sendcode:
		txa
		pha
		ldx #mfile
		jsr chkout
		pla
		tax
		lda char1,x
		jsr chrdly
		lda char2,x
		jsr chrdly
		lda char3,x
		jsr chrdly
		jsr clrchn
		ldx #1
		jmp tenwait
chrdly:
		jsr chrout
		lda #10
		sec
chrdly1:
		sbc #1
		bcs chrdly1
		rts

getnum0:
		jsr exit0
		jmp getnum1

// get a character from the modem
// if a character is available, returns with character in .A, carry clear, and status (st) zero
// if no character is available, returns 0 in .A, carry set, and status (st) 2

getnumx:
		jsr exit
getnum1:
		jsr displclk
		lda #0
		sta $0200
		lda ridbe
		cmp ridbs
		beq get1
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
		jmp get2
get1:
		lda #2
		sta $96
		sec
get2:
		lda $0200
		rts

rechand_retry_counter:
		.byte 0

rechand:
		sta gbsave

		lda #$00
		sta delay

rch1:
		lda #2
		sta rechand_retry_counter

		ldx gbsave
		jsr sendcode

rch2:

// wait for ack

		lda #1<<ack
		jsr accept
		beq rch3

// ack not received
		dec rechand_retry_counter
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
		lda pbuf1 + header_size_of_next_block
		sta bufcount
		sta recsize
		jsr recmodem

		lda $96
		cmp #recmodem_st_got_buffer
		beq rch5
		cmp #recmodem_st_timed_out
		beq rch3
		cmp #$04
		beq rch5
		cmp #$08
		beq rch3
rch5:
		rts
rch6:
		lda #1<<syn
		jsr accept
		bne rch3

		lda #$0a
		sta bufcount
rch7:
		ldx #syn
		jsr sendcode

		lda #1<<snb
		jsr accept
		beq rch8

		dec bufcount
		bne rch7
rch8:
		rts

tranhand:
		lda #$01
		sta delay
trh1:
		lda specmode
		beq trh2
		ldx #goo
		jsr sendcode
trh2:
		lda #(1<<goo) | (1<<bad) | (1<<snb)
		jsr accept
		bne trh1
		lda #$00
		sta specmode
		lda bitcnt
		cmp #goo
		bne trh6
		lda endflag
		bne trh8
		inc blocknum
		bne trh3
		inc blocknum+1
trh3:
		jsr thisbuf
		ldy #6
		lda ($64),y
		cmp #$ff
		bne trh4
		lda #1
		sta endflag
		lda bufpnt
		eor #1
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
		ldx #ack
		jsr sendcode
		lda #1<<snb
		jsr accept
		bne trh5
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
		lda #0
		rts
trh8:
		ldx #ack
		jsr sendcode
		lda #1<<snb
		jsr accept
		bne trh8
		lda #10
		sta bufcount
trh9:
		ldx #syn
		jsr sendcode
		lda #1<<syn
		jsr accept
		beq trha
		dec bufcount
		bne trh9
trha:
		lda #3
		sta bufcount
trhb:
		ldx #snb
		jsr sendcode
		lda #0
		jsr accept
		dec bufcount
		bne trhb
		lda #1
		rts

recmodem_index:
		.byte 0

recmodem:
		lda #0
		sta recmodem_index

rcm1:
		lda #$00
		sta jiffy
rcm2:
		jsr getnumx

		lda $96
		bne recmodem_no_byte_received

		ldy recmodem_index
		lda $0200
		sta pbuf1,y

		cpy #3
		bcs recmodem_not_ack_in_buffer

		sta codebuf,y
		cpy #2
		bne recmodem_not_ack_in_buffer

		lda codebuf
		cmp #'a'
		bne recmodem_not_ack_in_buffer
		lda codebuf+1
		cmp #'c'
		bne recmodem_not_ack_in_buffer
		lda codebuf+2
		cmp #'k'
		beq recmodem_ack_in_buffer

recmodem_not_ack_in_buffer:
		iny
		sty recmodem_index
		cpy bufcount
		bne rcm1

// got all of our bytes

		lda #recmodem_st_got_buffer
		sta $96
		rts

// we got an "ack" in the buffer
// treat that like a timeout

recmodem_ack_in_buffer:

		lda #recmodem_st_timed_out
		sta $96
		rts

recmodem_no_byte_received:

		lda jiffy
		cmp #recmodem_timeout_jiffies
		bcc rcm2

		lda #recmodem_st_timed_out
		sta $96
		rts

dummyblk:
		lda bufpnt
		eor #$01
		sta bufpnt
		jsr thisbuf
		ldy #5
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
		ldy #$07
dum1:
		jsr chrin
		sta ($64),y
		jsr commbyte
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
		ldy #5
		iny
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
		lda bufpnt
		bne thisbuf1
thisbuf0:
		lda #<pbuf1
		sta $64
		lda #>pbuf1
		sta $65
		rts
thisbuf1:
		lda #<pbuf2
		sta $64
		lda #>pbuf2
		sta $65
		rts

altbuf:
		lda bufpnt
		beq thisbuf1
		bne thisbuf0

checksum:
		lda #$00
		sta check1
		sta check1+1
		sta check1+2
		sta check1+3
		ldy #4
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
		ldy #0
		lda check1
		sta ($64),y
		iny
		lda check1+1
		sta ($64),y
		iny
		lda check1+2
		sta ($64),y
		iny
		lda check1+3
		sta ($64),y
		rts

transmit:
		jsr reset
		lda #$00
		sta endflag
		sta skpdelay
		sta dontdash
		lda #1
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
		sta ($64),y //6
tra1:
		jsr tranhand
		beq tra1
tra2:
		lda #0
		sta $0200
		rts

recieve:
		jsr reset
		lda #1
		sta blocknum
		lda #0
		sta blocknum+1
		sta endflag
		sta bufpnt
		sta pbuf1 + header_block_number_lsb
		sta pbuf1 + header_block_number_msb
		sta skpdelay
		lda #header_size
		sta pbuf1 + header_size_of_next_block
		lda #goo
rec1:
		jsr rechand
		lda endflag
		bne tra2
		jsr match
		bne rec5
		jsr clrchn

// first block

		lda bufcount
		cmp #header_size
		beq rec3

		ldx #dfile
		jsr chkout
		ldy #$07
rec2:
		lda pbuf1,y
		jsr chrout
		jsr commbyte
		iny
		cpy bufcount
		bne rec2
		jsr clrchn
rec3:
		lda pbuf1 + header_block_number_msb
		cmp #$ff
		bne rec4
		lda #$01
		sta endflag
		bne rec4a
rec4:
		jsr goodblok
rec4a:
		jsr reset
		lda #goo
		jmp rec1
rec5:
		jsr clrchn
		jsr badblok
		lda recsize
		sta pbuf1+4
		lda #bad
		jmp rec1

match:
		lda pbuf1
		sta check
		lda pbuf1+1
		sta check+1
		lda pbuf1+2
		sta check+2
		lda pbuf1+3
		sta check+3
		jsr thisbuf
		lda recsize
		sta bufcount
		jsr checksum
		lda pbuf1
		cmp check
		bne mch1
		lda pbuf1+1
		cmp check+1
		bne mch1
		lda pbuf1+2
		cmp check+2
		bne mch1
		lda pbuf1+3
		cmp check+3
		bne mch1
		lda #$00
		rts
mch1:
		lda #$01
		rts

rectype:
		lda defflag
		and #flag_filetype
		beq rct0
		rts
rct0:
		jsr reset
		lda #$00
		sta blocknum
		sta blocknum+1
		sta endflag
		sta bufpnt
		sta skpdelay
		lda #8
		sta pbuf1+4
		sta recsize
		lda #goo
rct1:
		jsr rechand
		lda endflag
		bne rct3
		jsr match
		bne rct2
		lda pbuf1+7
		sta filetyp
		lda #$01
		sta endflag
		lda #goo
		jmp rct1
rct2:
		lda recsize
		sta pbuf1+4
		lda #bad
		jmp rct1
rct3:
		lda #0
		sta $0200
		rts

trantype:
		lda defflag
		and #2
		beq trt0
		rts
trt0:
		jsr reset
		lda #$00
		sta endflag
		sta skpdelay
		lda #$01
		sta bufpnt
		sta dontdash
		lda #$ff
		sta blocknum
		sta blocknum+1
		jsr altbuf
		ldy #4
		lda #8
		sta ($64),y //4
		jsr thisbuf
		ldy #5
		lda #$ff
		sta ($64),y //5
		iny
		sta ($64),y //6
		lda filetyp
		iny
		sta ($64),y //7
		lda #1
		sta specmode
trt1:
		jsr tranhand
		beq trt1
		lda #0
		sta $200
		rts

dodelay:
		inc skpdelay
		lda skpdelay
		cmp #$03
		bcc dod1
		lda #$00
		sta skpdelay
		lda delay
		beq dod2
		rts
dod1:
		lda delay
		beq dod5
dod2:
		ldx #$78
		ldy #$00
dod4:
		dey
		bne dod4
		dex
		bne dod4
dod5:
		rts

prtdash:
		tax
		lda blocknum
		ora blocknum+1
		beq prd1
		lda dontdash
		bne prd1
		txa
		jsr dodash
prd1:
		rts

reset:
		jmp rsinabl

dodash:
		cmp #'-'
		beq dsh1
		jmp badblok
dsh1:
		jmp goodblok

screen:
		tsx
		inx
		inx
		stx stack
		ldy #0
scr2:
		lda #3
		sta pbuf1+$d400,y
		lda #7
		sta pbuf2+$d400,y
		iny
		bne scr2
		jsr nobytes
		jsr startclk
		jmp setup

nobytes:
		lda #0
		sta bytes
		sta bytes+1
		sta bytes+2
		sta blocks
		sta blocks+1
		sta badblks
		sta badblks+1
		rts

bytes:
		.byte 0,0,0
blocks:
		.word 0
badblks:
		.word 0
limit:
		.byte 0
bitpnt:
		.byte $20
bitcnt:
		.byte $0f
bitpat:
		.byte $04
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
oldtrans:
		.byte 0
dontdash:
		.byte $00
specmode:
		.byte $00

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
chkmark:
		lda #52
		jmp usetbl1

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

recname:
		lda #$00
		sta blocknum
		sta blocknum+1
		sta endflag
		sta bufpnt
		sta skpdelay
		lda #7+18
		sta pbuf1+4
		sta recsize
		lda #goo
rcn1:
		jsr rechand
		lda endflag
		bne rcn5
		jsr match
		bne rcn4
		ldx #7
		ldy #0
rcn2:
		lda pbuf1+7,y
		beq rcn3
		sta buffer,y
		iny
		cpy #18
		bne rcn2
rcn3:
		sty varbuf
		lda #<buffer
		sta varbuf+1
		lda #>buffer
		sta varbuf+2
		ldx #var_an_string
		jsr putvar
		lda #1
		sta endflag
		lda #1
		jmp rcn1
rcn4:
		lda recsize
		sta pbuf1+4
		lda #2
		jmp rcn1
rcn5:
		lda #0
		sta $0200
		rts

tranname:
		lda #$00
		sta endflag
		sta skpdelay
		lda #$01
		sta bufpnt
		sta dontdash
		lda #$ff
		sta blocknum
		sta blocknum+1
		jsr altbuf
		ldy #4
		lda #7+18
		sta ($64),y
		jsr thisbuf
		ldy #5
		lda #$ff
		sta ($64),y
		iny
		sta ($64),y
		lda $64
		pha
		lda $65
		pha
		ldx #var_an_string
		jsr usevar
		ldy #0
		cpy varbuf
		beq trn2
trn1:
		lda (varbuf+1),y
		sta buffer,y
		iny
		cpy #18
		bcc trn1
trn2:
		sty index
		pla
		sta $65
		pla
		sta $64
		ldx #0
		ldy #7
trn3:
		cpy index
		beq trn4
		lda buffer,x
		sta ($64),y
		iny
		inx
		bne trn3
trn4:
		cpx #18
		beq trn5
		lda #0
		sta ($64),y
		inx
		iny
		bne trn4
		lda #1
		sta specmode
trn5:
		jsr tranhand
		beq trn5
		lda #0
		sta $0200
		rts

startclk:
		lda #0
		ldy #3
startcl1:
		sta $dd08,y
		dey
		bpl startcl1
		rts

displclk:
		pha
		txa
		pha
		tya
		pha
		ldx #0
		ldy #3
displcl1:
		lda $dd08,y
		pha
		lsr
		lsr
		lsr
		lsr
		jsr displcl3
		pla
		and #15
		jsr displcl3
		dey
		beq displcl2
		lda #':'
		jsr displcl4
		jmp displcl1
displcl2:
		lda $dd08
		pla
		tay
		pla
		tax
		pla
		rts
displcl3:
		ora #$30
displcl4:
		sta pbuf3+tcount,x
		inx
		rts
