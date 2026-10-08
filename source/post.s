.encoding "petscii_mixed"

.var version = "03/22/90 01:08a"

#import "equat.s"

* = protostart "post.prg"

		jmp proto4
		.byte 255

// proto 4 for posts (++ post)

// variables used for the binary search

// "high" index

h_msb:
		.byte 0
h_lsb:
		.byte 0

// "low" index

l_msb:
		.byte  0
l_lsb:
		.byte 0

// current index

x_msb:
		.byte 0
x_lsb:
		.byte 0

// buffer for sending positioning commands for rel files

// struct position_command {
//     uint8 command// // "p"
//     uint8 channel// // must match the secondary address used when opening the file
//     uint8 recordNumberLoByte//
//     uint8 recordNumberHiByte//
//     uint8 positionWithinRecord//
//     uint8 carriageReturn//
// }

ptrcom:
		.text "p"
		.byte 2
ptr_lsb:
		.byte 0
ptr_msb:
		.byte 0
ptrpos:
		.byte 1, 13

// end of positioning command buffer

xx_lsb:
		.byte 0
xx_msb:
		.byte 0
ptr2_lsb:
		.byte 0
ptr2_msb:
		.byte 0
copy0:
		.byte $ff
		.word $ffff
copy1:
		.byte $ff
		.byte $ff
fake:
		.word copy2

// FIND      &,16
// Uses a binary search to find the string AN$ in the REL file.
//   Entry: AN$=sting to find
//          File 2 must be open to the REL file
//          File 15 must be open to the command channel
//   Exit:  if found then A%=value found, B%=position found
//          if not found then A%=0, B%=position to insert
//
// SAVEINDX  &,16,2
// Save an index to disk.
//   Entry: A$=drive#+filename, DV%=device
//
// MAKEINDX  &,16,3
// This will clear the index buffer.
//
// INSTINDX  &,16,4
// This will insert a value into the index buffer.
//   Entry: A%=value, B%=position
//
// DELTINDX  &,16,5
// This will delete a value from the index buffer.
//   Entry: B%=position
//
// NEXTINDX  &,16,6
// This will return the next value from the index buffer.
//   Entry: B%=current position
//   Exit:  A%=value at new position, B%=new position
//
// SETCRSKP  &,16,7
// This will set the # of Carriage Returns to skip when reading data. This
// allows fields other than the first one to be indexed.
//   Entry: A%=# of CRs
//
// FINDINDX  &,16,8 (from image 1.2, this is something else now)
// This will find the first occurance of the value given.
//   Entry: A%=value to find
//   Exit:  B%=position found at, or 0 if not found.

proto4:
		txa
		beq find //0
		dex
		beq loadindx //1
		dex
		beq saveindx //2
		dex
		beq makeindx //3
		dex
		beq instindx //4
		dex
		beq deltindx //5
		dex
		beq nextindx //6
		dex
		beq setcrskp //7
		dex
		beq loadpost //8
		dex
		beq savepost //9
		dex
		beq numbindx //10
		dex
		beq readpost //11
		rts

loadindx:
		jmp loadfile
saveindx:
		jmp savefile
makeindx:
		jmp makefile
instindx:
		jmp insert
deltindx:
		jmp delete
nextindx:
		jmp getnext
setcrskp:
		jmp setskip
loadpost:
		jmp postload
savepost:
		jmp postsave
numbindx:
		jmp indxcnt
readpost:
		jmp postread

// proto 4 - relfile indexer

// search for an$ in file

// get handle to search for

find:
		ldx #var_an_string
		jsr usevar

// copy variable to buffer

		ldy #0
findloop:
		lda (varbuf+1),y
		sta buffer,y
		iny
		cpy varbuf
		bcc findloop

// add zero byte termination

		lda #0
		sta buffer,y
		sty xlen1

// setting up for binary search

// high = # users?

		lda last
		ldx last+1
		sta h_msb
		stx h_lsb

// low = 1

		lda #0
		ldx #1
		sta l_msb
		stx l_lsb

// check the first entry

		lda l_msb
		ldx l_lsb
		sta x_msb
		stx x_lsb

		jsr check
		beq found_it
		bcs find1

//entry goes before the first index

		jmp xputavar

// check the last entry

find1:
		lda h_msb
		ldx h_lsb
		sta x_msb
		stx x_lsb
		jsr check
		beq found_it
		bcc find2

// entry goes after the last index
// increment high index

		lda h_msb
		ldx h_lsb
		inx
		bne find1a
		clc
		adc #1
find1a:
		sta x_msb
		stx x_lsb
		jmp xputavar

found_it:
		jmp putavar

// get midpoint

find2:
		lda l_msb
		cmp h_msb
		bne find3
		lda l_lsb
		cmp h_lsb
		bne find3

// low == high, so entry was not found

		jmp xputavar

find3:
		clc

// x = low + high

		lda l_lsb
		adc h_lsb
		sta x_lsb
		lda l_msb
		adc h_msb
		sta x_msb

// x = x / 2

		lsr x_msb
		ror x_lsb

// test (l != x)

		lda x_msb
		cmp l_msb
		bne find4
		lda x_lsb
		cmp l_lsb
		bne find4

// l == x
// force l = h, x = h

		lda h_msb
		ldx h_lsb
		sta l_msb
		stx l_lsb
		sta x_msb
		stx x_lsb

// l != x
// do pointer command, and input

find4:
		jsr check
		beq found_it

		lda x_msb
		ldx x_lsb
		bcc find11
		sta l_msb
		stx l_lsb
		jmp find2

find11:
		sta h_msb
		stx h_lsb
		jmp find2

check:

// send the command to position to the target record

		jsr sendptr

		lda skip
		sta skip2
		beq check2
check1:
		dec skip2
check2:
		ldx #2
		ldy #0
		jsr dskin

		lda skip2
		bne check1
		jmp compare

sendptr:
		jsr calcptr
sendcom:
		ldx #15
		jsr chkout
		ldy #0
		ldx #6
sendloop:
		lda ptrcom,y
		jsr chrout
		iny
		dex
		bne sendloop
		jmp clrchn

copy2:
		.byte $ff
		.word $ffff

// ptr = memory(last + x * 2)

calcptr:
		lda x_lsb
		asl
		tay
		lda x_msb
		rol
		tax
		clc
		tya
		adc #<last
		sta $fb
		txa
		adc #>last
		sta $fc
		ldy #0
		lda ($fb),y
		sta ptr_msb
		iny
		lda ($fb),y
		sta ptr_lsb
		rts

compare:
		ldy #0
comploop:
		lda buffer,y
		cmp buf2,y
		bne compare1
		iny
		cpy xlen1
		beq compare2
		cpy index
		bne comploop
compare2:
		ldy xlen1
		cpy index
compare1:
		rts

// length of the string in "buffer"

xlen1:
		.byte 0

//load index file to end of proto

loadfile:

// get filename variable

		ldx #var_a_string
		jsr usevar

// set filename for open

		lda varbuf
		ldx varbuf+1
		ldy varbuf+2
		jsr setnam

// get device number variable

		ldx #var_dv_integer
		jsr usevar

// set file number and secondary address

		lda #8
		ldx varbuf+1
		ldy #0
		jsr setlfs

// load file to memory

		lda #0
		ldx #<last
		ldy #>last
		jsr loadf

indxcnt:
		lda last
		ldx last+1
		sta varbuf
		stx varbuf+1
		ldx #var_a_integer
		jmp putvar

//save index file

savefile:

// get filename variable

		ldx #var_a_string
		jsr usevar

// set filename for open

		lda varbuf
		ldx varbuf+1
		ldy varbuf+2
		jsr setnam

// get device number variable

		ldx #var_dv_integer
		jsr usevar

// set file number and secondary address

		lda #8
		ldx varbuf+1
		ldy #0
		jsr setlfs

		lda #<last
		ldx #>last
		sta varbuf
		stx varbuf+1

// calculate address of the end of the index data
// XY = &indexdata  + indexdata.count * 2

		lda last+1
		asl
		tax
		lda last
		rol
		tay
		clc
		txa
		adc #<last
		tax
		tya
		adc #>last
		tay

// add the size of the count, plus one more byte (needed by ROM save routine)
// XY += 3

		clc
		txa
		adc #3
		tax
		tya
		adc #0
		tay

// call ROM save routine
// inputs:
//  A = Address of zero page register holding start address of memory area to save
//  X/Y = End address of memory area plus 1.
		
		lda #varbuf
		jmp savef

//make an empty index

makefile:
		lda #0
		sta last
		sta last+2
		lda #0
		sta last+1
		sta last+3
		rts

xputavar:

// zero out record pointer
		lda #0
		sta ptr_lsb
		sta ptr_msb

putavar:

// a% = record pointer (reverse order because of position command)

		lda ptr_msb
		ldx ptr_lsb
		sta varbuf
		stx varbuf+1

		ldx #var_a_integer
		jsr putvar

// b% = x

		lda x_msb
		ldx x_lsb
		sta varbuf
		stx varbuf+1
		ldx #var_b_integer
		jsr putvar
		lda ptr_lsb
		ora ptr_msb
		rts

//insert into index
// a%=id, b%=pos
//x=pos

insert:
		ldx #var_b_integer
		jsr usevar

		lda varbuf
		ldx varbuf+1
		sta x_msb
		stx x_lsb

//last++

		inc last+1
		bne insert1a
		inc last

//ptr=id

insert1a:
		ldx #var_a_integer
		jsr usevar

		lda varbuf
		ldx varbuf+1
		sta ptr_msb
		stx ptr_lsb

//h=ptr

insert2:
		lda ptr_lsb
		ldx ptr_msb
		sta h_lsb
		stx h_msb
		jsr calcptr
		ldy #0

//*x=h

		lda h_msb
		sta ($fb),y
		iny
		lda h_lsb
		sta ($fb),y

//if x=last then done

		lda x_lsb
		cmp last+1
		bne insert3
		lda x_msb
		cmp last
		bne insert3
		rts

//x++

insert3:
		inc x_lsb
		bne insert3a
		inc x_msb
insert3a:
		jmp insert2

//delete from index
// b%=pos

delete:
		ldx #var_b_integer
		jsr usevar

		lda varbuf
		ldx varbuf+1
		sta x_msb
		stx x_lsb

//*x=*(x+1)

delete1:
		lda x_msb
		cmp last
		bne delete2
		lda x_lsb
		cmp last+1
		beq delete3
delete2:
		jsr calcptr

		ldy #3
		lda ($fb),y
		pha
		dey
		lda ($fb),y
		tax
		dey
		pla
		sta ($fb),y
		dey
		txa
		sta ($fb),y

//x++

		inc x_lsb
		bne delete2a
		inc x_msb
delete2a:
		jmp delete1

//last--

delete3:
		lda last+1
		bne delete3a
		dec last
delete3a:
		dec last+1

//done

		rts

getnext:
		ldx #var_b_integer
		jsr usevar

		lda varbuf
		ldx varbuf+1
		sta x_msb
		stx x_lsb

		inc x_lsb
		bne getnext1
		inc x_msb
getnext1:
		jsr calcptr
		jmp putavar

setskip:
		sty skip
		rts

// requested number of lines to skip when reading a record

skip:
		.byte 0

// holds the counter used to skip lines while reading, decrements to zero

skip2:
		.byte 0

postload:
		lda copy1
		clc
		adc postsave+1
		eor 766
		bne getnext-1
		jsr makefile

		ldx #var_b_integer
		jsr usevar

		lda varbuf+1
		sta ptr_lsb
		lda varbuf
		sta ptr_msb

		lda #<last
		sta $fb
		lda #>last
		sta $fc

postld1:
		jsr sendcom

		ldx #2
		ldy #3
		jsr dskin

		lda buf2
		sta ptr_lsb
		lda buf2+1
		sta ptr_msb

		ldy buf2+2
		sty l_msb

		ldx #2
		cpy #0
		beq postld3
		jsr dskin
		ldy #0
postld2:
		lda buf2,y
		sta ($fb),y
		iny
		cpy l_msb
		bne postld2
		lda $fb
		clc
		adc l_msb
		sta $fb
		bcc postld3
		inc $fc
postld3:
		lda ptr_lsb
		cmp #0
		bne postld1
		lda ptr_msb
		cmp #0
		bne postld1
		jmp indxcnt

// save pointers

postsave:
		lda copy0
		clc
		adc postread+1
		eor 765
		bne postsave-3

		ldx #var_a_integer
		jsr usevar

		lda varbuf+1
		sta xx_lsb
		sta ptr_lsb
		lda varbuf
		sta xx_msb
		sta ptr_msb

		jsr sendcom

		ldx #1
		jsr tenwait

		jsr sendcom

		ldx #2
		jsr chkout

		lda #0
		jsr chrout
		jsr chrout
		jsr chrout

		lda #13
		jsr chrout

		jsr sendcom

		ldx #var_b_integer
		jsr usevar

		lda varbuf+1
		sta ptr_lsb
		lda varbuf
		sta ptr_msb

		lda #<last
		sta postsv2+1
		lda #>last
		sta postsv2+2

		lda last+1
		asl
		tax
		lda last
		rol
		tay
		clc
		txa
		adc #<last
		tax
		tya
		adc #>last
		tay
		clc
		txa
		adc #2
		sta l_msb
		tya
		adc #0
		sta l_lsb
postsv0:
		jsr sendcom

		ldx #2
		ldy #2
		jsr dskin

		jsr sendcom

		lda ptr_lsb
		sta ptr2_lsb
		lda ptr_msb
		sta ptr2_msb

		ldx #1
		jsr tenwait

		jsr sendcom

		lda ptr_lsb
		sta varbuf+1
		lda ptr_msb
		sta varbuf

		ldx #var_b_integer
		jsr putvar

		lda buf2
		sta ptr_lsb
		lda buf2+1
		sta ptr_msb

		cmp #0
		bne postsv1
		lda ptr_lsb
		cmp #0
		bne postsv1

		lda xx_lsb
		sta buf2
		lda xx_msb
		sta buf2+1
		inc xx_lsb
		bne postsv1a
		inc xx_msb
postsv1a:
		lda xx_lsb
		sta ptr_lsb
		lda xx_msb
		sta ptr_msb

		jsr sendcom

		ldx #2
		jsr chkout

		lda #0
		jsr chrout
		jsr chrout
		jsr chrout

		lda #13
		jsr chrout

		jsr sendcom

		lda ptr2_lsb
		sta ptr_lsb
		lda ptr2_msb
		sta ptr_msb

		jsr sendcom

		ldx #1
		jsr tenwait

		jsr sendcom

		lda buf2
		sta ptr_lsb
		lda buf2+1
		sta ptr_msb
postsv1:
		ldy #0
postsv2:
		lda $ffff
		sta buf2+3,y
		iny
		inc postsv2+1
		bne postsv3
		inc postsv2+2
postsv3:
		lda postsv2+1
		cmp l_msb
		bne postsv4
		lda postsv2+2
		cmp l_lsb
		bne postsv4

		lda #0
		sta ptr_lsb
		sta ptr_msb
		sta buf2
		sta buf2+1

		jmp postsv5

postsv4:
		cpy #76
		bne postsv2
postsv5:
		sty buf2+2
		iny
		iny
		iny
		sty h_msb

		ldy #0
		ldx #2
		jsr chkout

postsv6:
		lda buf2,y
		jsr chrout
		iny
		cpy h_msb
		bne postsv6

		lda #13
		jsr chrout

		jsr clrchn

		lda ptr_lsb
		bne postsv7
		lda ptr_msb
		bne postsv7
		rts
postsv7:
		jmp postsv0

postread:
		lda copy2
		clc
		adc postload+1
		eor 767
		bne postsv7-1
		jsr zero
		ldx #var_rc_float
		jsr putvar
		ldx #var_sh_float
		jsr putvar
		lda #0
		sta 2038
		sta 2024
postrd0:
		jsr minusone
		ldx #var_lp_float
		jsr putvar
		ldx #2
		ldy #0
		jsr reader
		lda buf2
		cmp #'^'
		bne postrd1
		ldx #var_a_string
		jsr usevar
		lda varbuf
		cmp #1
		bne postrd1
		jmp postrd2
postrd1:
		ldx #var_rc_float
		jsr usevar
		lda varbuf
		bne postrd2
		jmp postrd0
postrd2:
		jsr zero
		ldx #var_lp_float
		jmp putvar

// copy variable number X to the variable buffer (var)

usevar:
		lda #29
		jmp usetbl1

tenwait:
		lda #22
		jmp usetbl1

// input from disk (&,2,X,Y)
// inputs:
//  X = file number (0 for last value used)
//  Y = bytes to read (0 means read up to carriage return, max 80)
// data read will be in the a$ variable, and in buf2

dskin:
		lda #2
		jmp usetbl1

// write the variable buffer (var) to variable number X

putvar:
		lda #30
		jmp usetbl1

outastr:
		lda #0
		jmp usetbl1

// load "0" into the variable buffer

zero:
		lda #31
		jmp usetbl1

// load "-1" into the variable buffer

minusone:
		lda #32
		jmp usetbl1

reader:
		lda #3
		jmp usetbl1

vers:
		.text version
		.byte 13
		.text "So long, and thanks for all the fish!"
		.byte 13
		.text "---------------------------------------"
		.byte 13
		.text "Copr.1990 New Image"

// index file is stored in memory here

last:

// struct indexdata {
//   uint16 count//
//   uint16 data()//
// }



