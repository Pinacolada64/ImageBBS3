.pseudopc wedge_exec_address {
.namespace wedge {

// jump table

// xx00: install w/o error trap
// xx03: install w/error trap
// xx06: load after filename is set
// xx09: save array pointers
// xx0c: restore array pointers

start:
		jmp install
		jmp install0
		jmp openroom
		jmp arraysv0
		jmp arrayrs0
		jmp collect
wgone0:
		jmp wgone
weval0:
		jmp weval
wtrap0:
		jmp wtrap
wfunc0:
		tsx
		txa
		tay
		lda #$00
		jmp $b391

filename_len:
		.byte 0
fdev:
		.byte 0

tload:
		jsr chrget
		jsr getfile
		jsr openroom
		jmp gone2

openroom:
		ldy #0
openroo1:
		cpy $b7
		beq openroo2
		lda ($bb),y
		sta fbuf,y
		iny
		cpy #20
		bcc openroo1
openroo2:
		sty filename_len
		lda $ba
		sta fdev
		lda $b9
		and #31
		sta loadflag
		jsr collect
		ldx $31
		ldy $32
		stx $ac
		sty $ad
		ldx $33
		ldy $34
		stx $ae
		sty $af
		stx $31
		sty $32
		ldx #$2f
		jsr oprm
		ldx #$2d
		jsr oprm

loadfile:
		lda #127
		ldx fdev
		ldy #0
		jsr setlfs
		ldx #<fbuf
		ldy #>fbuf
		lda filename_len
		jsr setnam
		jsr openf
		ldx #127
		jsr chkin
		jsr chrin
		jsr chrin
		jsr chrin
		jsr chrin
		jsr chrin
		sta l1x+1
		jsr chrin
		sta l2x+1
		jsr clrchn
		lda #127
		jsr closef
		jsr scan0
		lda #127
		ldx fdev
		ldy #0
		jsr setlfs
		ldx #<fbuf
		ldy #>fbuf
		lda filename_len
		jsr setnam
		lda #0
		ldx $ae
		ldy $af
		jsr loadf
		bcc loadfil1
		jsr chopfile
loaderr:
		ldx #29
		jmp error
loadfil1:
		jsr linkprg

		lda l1x+1
		cmp 57
		lda l2x+1
		sbc 58
		bcs chopfile
		lda #<(prgstart-1)
		sta $7a
		lda #>(prgstart-1)
		sta $7b

chopfile:
		ldx #<65535
		ldy #>65535
chopfil1:
		stx l1x+1
		sty l2x+1
		jsr scan0
		ldy #0
		tya
		sta ($ae),y
		iny
		sta ($ae),y
		clc
		lda #2
		adc $ae
		sta $ae
		lda #0
		adc $af
		sta $af

closroom:
		ldx $2d
		ldy $2e
		stx $ac
		sty $ad
		ldx $ae
		ldy $af
		stx $2d
		sty $2e
		ldx #$2f
		jsr clrm
		ldx #$31

clrm:
		sei
		ldy #0
		lda 0,x
		sta $b0
		lda 1,x
		sta $b1
clrm1:
		lda ($ac),y
		sta ($ae),y
		lda $ac
		cmp 0,x
		bne clrm0
		lda $ad
		cmp 1,x
		beq clrm4
clrm0:
		inc $ac
		bne clrm2
		inc $ad
clrm2:
		inc $ae
		bne clrm3
		inc $af
clrm3:
		jmp clrm1
clrm4:
		lda $ae
		sta 0,x
		lda $af
		sta 1,x
		cli
		rts

scan0:
		ldx $2b
		ldy $2c
		stx $ac
		sty $ad
scan1:
		stx $ae
		sty $af
		ldy #2
		lda ($ae),y
l1x:
		cmp #0
		iny
		lda ($ae),y
l2x:
		sbc #0
		bcs scan3
scan2:
		lda $ae
		ldx $af
		sta $ac
		stx $ad
		ldy #0
		lda ($ae),y
		tax
		iny
		lda ($ae),y
		tay
		bne scan1
scan3:
		rts

oprm:
		sei
		ldy #0
		lda 0,x
		sta $b0
		lda 1,x
		sta $b1
oprm1:
		lda $ac
		cmp 0,x
		bne oprm0
		lda $ad
		cmp 1,x
		beq oprm4
oprm0:
		lda $ac
		bne oprm2
		dec $ad
oprm2:
		dec $ac
		lda $ae
		bne oprm3
		dec $af
oprm3:
		dec $ae
		lda ($ac),y
		sta ($ae),y
		jmp oprm1
oprm4:
		lda $ae
		sta 0,x
		lda $af
		sta 1,x
		cli
		rts

pokefix:
		lda $15
		cmp #$40
		bcc pokefix1
		cmp #$43
		bcc pokefix0
		cmp #$46
		bcc pokefix1
		cmp #$4a
		bcs pokefix1
		sec
		sbc #$03
pokefix0:
		sec
		sbc #$30
		sta $15
pokefix1:
		rts

tpoke:
		jsr chrget
		jsr getnum
		jsr pokefix
		ldy #0
		txa
		sta ($14),y
		jmp gone2

tsys:
		jsr chrget
		jsr frmnum
		jsr getadr
		lda $15
		cmp #$ff
		beq tsys1
		cmp #$c0
		beq tsys1
		jmp ilqerr
tsys1:
		jsr syscll
		jmp gone2

tnew:
		jsr chrget
		jsr linget
		ldx $14
		ldy $15
		jsr chopfil1
		jmp gone2

thex:
		ldx #0
		stx $62
		stx $63
thex1:
		jsr chrget
		bcc thex2
		cmp #'g'
		bcs thex5
		cmp #'a'
		bcc thex5
		sbc #7
thex2:
		and #$f
		ldx #4
thex3:
		asl $63
		rol $62
		bcs thex4
		dex
		bne thex3
		ora $63
		sta $63
		bcc thex1
thex4:
		jmp ilqerr
thex5:
		ldx #$90
		sec
		jmp retval

tpeek:
		jsr chrget
		jsr parchk
		lda $14
		pha
		lda $15
		pha
		jsr getadr
		jsr pokefix
		ldy #0
		lda ($14),y
		tay
		pla
		sta $15
		pla
		sta $14
		jmp retbyt

tampr:
		jsr chrget
		jsr getaxy
		jsr usetbl1
		jmp gone2

wgone:
		lda 51
		cmp 49
		lda 52
		sbc 50
		bne wgone1
		jsr collect
		lda 51
		cmp 49
		lda 52
		sbc 50
		bne wgone1
// less than 256 bytes free, force
// out of memory error for safety
		ldx #1
		jsr arrayrs0
		ldx #16
		jmp error //outofm
wgone1:
		lda #r6510_basic_ram
		sta r6510
		jsr trace
		lda #r6510_normal
		sta r6510
		jsr chrget
		cmp #'&'
		beq ampr0
		cmp #poketok
		beq poke0
		cmp #systok
		beq sys0
		cmp #loadtok
		beq load0
		cmp #newtok
		beq new0
		jsr chrgot
		jmp gone1

weval:
		jsr chrget
		ldx #0
		stx $d
		cmp #'$'
		beq hex0
		cmp #peektok
		beq peek0
		jsr chrgot
		jmp eval1

ampr0:
		jmp tampr
poke0:
		jmp tpoke
sys0:
		jmp tsys
load0:
		jmp tload
new0:
		jmp tnew
hex0:
		jmp thex
peek0:
		jmp tpeek

getaxy:
		jsr getparm
		stx 780
		jsr getparm
		stx 781
		jsr getparm
		stx 782
		lda 780
		ldx 781
		ldy 782
		rts

getparm:
		jsr chrgot
		ldx #0
		cmp #','
		bne getparm1
		jsr getbytc
getparm1:
		rts

wtrap:
		stx $030c
		lda $39
		sta $030d
		lda $3a
		sta $030e
		lda #<$e38b
		sta $300
		lda #>$e38b
		sta $301
		ldx #$fa
		txs
		lda #25
		sta 22
		lda #<trapline
		sta $14
		lda #>trapline
		sta $15
		jsr $a8a3
		jmp $a7ae

install:
		lda #<$e38b
		ldx #>$e38b
		jmp install1
install0:
		lda #<wtrap0
		ldx #>wtrap0
install1:
		sta $300
		stx $301
		lda #<wgone0
		ldx #>wgone0
		sta $308
		stx $309
		lda #<weval0
		ldx #>weval0
		sta $30a
		stx $30b
		lda #<wfunc0
		ldx #>wfunc0
		sta $311
		stx $312
		rts

arrayoff:
		txa
		and #7
		asl
		asl
		tax
		ldy #2
		rts

//* copy pointers for arrays *
arraysv0:
		jsr arrayoff
arsv1:
		sec
		lda $2f,y
		sbc $2d
		sta arryptrs+0,x
		lda $30,y
		sbc $2e
		sta arryptrs+1,x
		inx
		inx
		dey
		dey
		bpl arsv1
		rts

//* restore pointers for arrays *
arrayrs0:
		lda $2f
		sta $ac
		lda $30
		sta $ad
		jsr arrayoff
arrs1:
		clc
		lda arryptrs+0,x
		adc $2d
		sta $2f,y
		lda arryptrs+1,x
		adc $2e
		sta $30,y
		inx
		inx
		dey
		dey
		bpl arrs1
		lda $2f
		sta $ae
		lda $30
		sta $af
		ldy #0
		beq arrs2
arrs3:
		inc $ac
		bne arrs3a
		inc $ad
arrs3a:
		inc $ae
		bne arrs2
		inc $af
arrs2:
		lda ($ac),y
		sta ($ae),y
		lda $ae
		cmp $31
		bne arrs3
		lda $af
		cmp $32
		bne arrs3
		rts

collect:
		lda #>gc
		ldy #>gchide
		ldx #gclen
		jsr swapper
		jsr gc
		jmp swapagn

}
}
