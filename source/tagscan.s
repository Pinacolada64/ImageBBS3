#import "equat.s"

* = protostart "tagscan.prg"

// tagscan: object/inventory helper, loaded at $c000 and called with &,16.
//
// Purpose (inferred; no BASIC caller has been found): it looks like the
// inventory engine for an online adventure-style game. Objects have a type
// ("tag"), a location (a user number, or presumably a room), and flag bits.
// A user's inventory is built as a list of object numbers, and "definitions"
// say which object type can be assembled from up to three piece types.
//
// & passes &,16,x,y in the X and Y registers: X selects the function (see
// table below) and Y is ignored. Results come back in a% via &,30.
//
// All three arrays are BASIC integer arrays (2 bytes per element, high
// byte first), passed by naming element 0 (or list%(x) for findobjd).
// Element 0 of each holds the count in its low byte. Only low bytes are
// used for counts and object numbers, so each table holds at most 255 entries.
//
// list%(n): list of object numbers (indexes into ob%)
//   list%(0)     count of entries
//   list%(1..n)  object numbers
//
// ob%(f,n): objects. BASIC varies the first subscript fastest, so each object
// is one record of objsize bytes ((fields+1)*2 for dim ob%(fields,n)).
//   ob%(0,0)     count of objects
//   ob%(0,n)     flag bits (makelist skips objects with any of "bits" set)
//   ob%(1,n)     type
//   ob%(2,n)     location (makelist compares it to a user number)
//
// od%(f,n): definitions, records of defsize bytes
//   od%(0,0)     count of definitions
//   od%(0,n)     bits (unused here)
//   od%(1,n)     type of object this definition produces
//   od%(2..4,n)  types of up to three pieces it is built from (0 = none)

.label zp1= $71 // pointer

// offset to bits in objlist (ob)
.label obbitoff = 0
// offset to type in objlist (ob)
.label obtypoff = 2
// offset to loc in objlist (ob)
.label oblocoff = 4
// offset to bits in deflist (od)
.label odbitoff = 0
// offset to type in deflist (od)
.label odtypoff = 2
// offset to piece1 in deflist (od)
.label odpc1off = 4
// offset to piece2 in deflist (od)
.label odpc2off = 6
// offset to piece3 in deflist (od)
.label odpc3off = 8

// syntax:

// scanvirt: &,16,0,0,list(),obj(),objsize,def(),defsize
// findobjd: &,16,1,0,list(x),obj(),objsize,def(),defsize
// haveobjt: &,16,2,0,list(),obj(),objsize,def(),defsize,objtyp
// makelist: &,16,3,0,list(),obj(),objsize,def(),usernumber
//
// (makelist actually takes defsize too, then two words:
//  &,16,3,0,list(),obj(),objsize,def(),defsize,location,bits)
//
// scanvirt: combine pieces in list() into the objects that def() builds
// findobjd: a% = definition number for object list(x), or 0
// haveobjt: a% = position in list() of an object of type objtyp, or 0
// makelist: fill list() with objects at location that have none of bits

// parse the parameters common to every function
entry1:
		lda #r6510_normal
		sta r6510
		stx func
		jsr fnvarx
		stx lstptr
		sty lstptr+1
		jsr fnvarx
		stx objptr
		sty objptr+1
		jsr evalbytx
		stx objsiz
		jsr fnvarx
		stx defptr
		sty defptr+1
		jsr evalbytx
		stx defsiz

// read the counts from element 0 of each array (for findobjd, objnum
// is instead the object number in list(x)), then dispatch on func
entry2:
		lda lstptr
		sta varbuf
		lda lstptr+1
		sta varbuf+1
		ldy #1
		lda (varbuf),y
		sta objnum

		lda objptr
		sta varbuf
		lda objptr+1
		sta varbuf+1
		ldy #1
		lda (varbuf),y
		sta objcnt

		lda defptr
		sta varbuf
		lda defptr+1
		sta varbuf+1
		ldy #1
		lda (varbuf),y
		sta defcnt

		lda func
		cmp #4
		bcs abort
		asl
		tax
		lda table,x
		sta jump+1
		lda table+1,x
		sta jump+2
jump:
		jmp abort
abort:
		rts

table:
		.word scanvirt //0
		.word findobjd //1
		.word haveobjt //2
		.word makelist //3

// a% = X, using &,30
putint:
		stx varbuf+1
		lda #0
		sta varbuf
		ldx #var_a_integer
putvar:
		lda #30
		jmp usetbl1

func:
		.byte 0

lstptr:
		.word 0
target:
		.word 0
bitval:
		.word 0

defptr:
		.word 0
defsiz:
		.byte 0
defcnt:
		.byte 0
defnum:
		.byte 0

objptr:
		.word 0
objsiz:
		.byte 0
objtyp:
		.word 0
objnum:
		.byte 0
objcnt:
		.byte 0

piece1:
		.byte 0
piece2:
		.byte 0
piece3:
		.byte 0

deltmp:
		.byte 0
scatmp:
		.byte 0

change:
		.byte 0

// skip a comma, find a variable (PTRGET); X/Y = address of its value
fnvarx:
		jsr chkcom
		jsr $b08b
		ldx $47
		ldy $48
		rts

// skip a comma, evaluate a byte into X
evalbytx:
		jsr chkcom
		jsr $0079
		jmp $b79e

// skip a comma, evaluate a 16-bit number; X = low byte, Y = high byte
// (callers store Y first, keeping the high-byte-first order of BASIC integers)
getword:
		jsr chkcom
		jsr $ad8a
		jsr $b7f7
		ldx $14
		ldy $15
		rts

// A/Y = address of list(X); carry set if X is 0 or more than objnum
calclst:
		lda lstptr
		ldy lstptr+1
		cpx #0
		beq calclst3
		cpx objnum
		beq calclst1
		bcs calclst3
calclst1:
		clc
		adc #2
		bcc calclst2
		iny
calclst2:
		dex
		bne calclst1
		clc
calclst3:
		rts

// look in list() for an object whose type is objtyp
// carry clear: found, X = position in list(); carry set: not found
// note: the count is compared after the first entry is checked, so an empty
// list is scanned through 255 entries past its end
scanlst:
		lda lstptr
		sta varbuf+4
		lda lstptr+1
		sta varbuf+5
		ldx #0
		stx scatmp
scanlst1:
		inc scatmp
		clc
		lda varbuf+4
		adc #2
		sta varbuf+4
		bcc scanlst2
		inc varbuf+5
scanlst2:
		ldy #1
		lda (varbuf+4),y
		tax
		jsr calcobj
		sta varbuf
		sty varbuf+1
		ldx scatmp
		bcs scanlst3
		ldy #obtypoff
		lda (varbuf),y
		iny
		cmp objtyp
		bne scanlst3
		lda (varbuf),y
		cmp objtyp+1
		beq scanlst4
scanlst3:
		cpx objnum
		bne scanlst1
		sec
		rts
scanlst4:
		clc
		rts

// A/Y = address of object X's record; carry set if X is 0 or more than objcnt
calcobj:
		lda objptr
		ldy objptr+1
		cpx #0
		beq calcobj3
		cpx objcnt
		beq calcobj1
		bcs calcobj3
calcobj1:
		clc
		adc objsiz
		bcc calcobj2
		iny
calcobj2:
		dex
		bne calcobj1
		clc
calcobj3:
		rts

// find the first object (anywhere) whose type is objtyp
// carry clear: found, X = object number; carry set: not found
// (same empty-table problem as scanlst)
scanobj:
		lda objptr
		sta varbuf
		lda objptr+1
		sta varbuf+1
		ldx #0
scanobj1:
		inx
		clc
		lda varbuf
		adc objsiz
		sta varbuf
		bcc scanobj2
		inc varbuf+1
scanobj2:
		ldy #obtypoff
		lda (varbuf),y
		cmp objtyp
		bne scanobj3
		iny
		lda (varbuf),y
		cmp objtyp+1
		beq scanobj4
scanobj3:
		cpx objcnt
		bne scanobj1
		sec
		rts
scanobj4:
		clc
		rts

// A/Y = address of definition X's record; carry set if X is 0 or more than
// defcnt (not called anywhere)
calcdef:
		lda defptr
		ldy defptr+1
		cpx #0
		beq calcdef3
		cpx defcnt
		beq calcdef1
		bcs calcdef3
calcdef1:
		clc
		adc defsiz
		bcc calcdef2
		iny
calcdef2:
		dex
		bne calcdef1
		clc
calcdef3:
		rts

// find the definition that produces type objtyp
// carry clear: found, X = definition number; carry set: not found
// (same empty-table problem as scanlst)
scandef:
		lda defptr
		sta varbuf
		lda defptr+1
		sta varbuf+1
		ldx #0
scandef1:
		inx
		clc
		lda varbuf
		adc defsiz
		sta varbuf
		bcc scandef2
		inc varbuf+1
scandef2:
		ldy #odtypoff
		lda (varbuf),y
		iny
		cmp objtyp
		bne scandef3
		lda (varbuf),y
		cmp objtyp+1
		beq scandef4
scandef3:
		cpx defcnt
		bne scandef1
		sec
		rts
scandef4:
		clc
		rts

// function 1: a% = number of the definition for the type of object list(x),
// or 0 if the object number is out of range or no definition matches
findobjd:
		ldx objnum
		jsr calcobj
		bcs findobj1
		sta varbuf
		sty varbuf+1
		ldy #obtypoff
		lda (varbuf),y
		lda (varbuf),y // redundant
		iny
		sta objtyp
		lda (varbuf),y
		sta objtyp+1
		jsr scandef
		bcc findobj2
findobj1:
		ldx #0
findobj2:
		jmp putint

// function 0: build "virtual" objects from their pieces.
// For each definition, if list() holds an object of every piece type, add
// the first object of the definition's type to list() and remove the
// pieces. Repeat until a pass makes no change, so built objects can be
// pieces of other objects.
// Only list() changes: BASIC has to update the objects' locations itself.
// Notes: a definition needing two pieces of one type is met by one object
// (scanlst finds the same entry twice); definitions that build each other
// (A from B, B from A) loop forever; an empty def() is scanned past its end.
scanvirt:
		lda #0
		sta change
		lda defptr
		sta varbuf+2
		lda defptr+1
		sta varbuf+3
		lda #0
		sta defnum
scanvir1:
		inc defnum
		clc
		lda varbuf+2
		adc defsiz
		sta varbuf+2
		bcc scanvir2
		inc varbuf+3
scanvir2:
		jsr checkdef
		lda defnum
		cmp defcnt
		bne scanvir1
		lda change
		bne scanvirt
		rts

// try to build the definition at (varbuf+2); sets change if it was built
checkdef:
		ldy #odpc1off
		lda (varbuf+2),y
		iny
		ora (varbuf+2),y
		bne checkd1
		ldy #odpc2off
		lda (varbuf+2),y
		iny
		ora (varbuf+2),y
		bne checkd1
		ldy #odpc3off
		lda (varbuf+2),y
		iny
		ora (varbuf+2),y
		bne checkd1
checkd0:
		rts // no pieces, a piece is missing, or no object of the result type

// find each piece in list() (position 0 for an unused piece)
checkd1:
		ldy #odpc1off
		jsr checkpc
		bcs checkd0
		stx piece1
		ldy #odpc2off
		jsr checkpc
		bcs checkd0
		stx piece2
		ldy #odpc3off
		jsr checkpc
		bcs checkd0
		stx piece3
// find an object of the type this definition produces, add it to list(),
// then clear the pieces' entries and close up the gaps
		ldy #odtypoff
		lda (varbuf+2),y
		sta objtyp
		iny
		lda (varbuf+2),y
		sta objtyp+1
		jsr scanobj
		bcs checkd0
		jsr addpc
		ldx piece1
		jsr deletpc
		ldx piece2
		jsr deletpc
		ldx piece3
		jsr deletpc
checkd7:
		jsr scandel
		lda #1
		sta change
		rts

// set list(X) to 0 (does nothing if X is 0, an unused piece)
deletpc:
		jsr calclst
		bcs deletpc1
		sta varbuf
		sty varbuf+1
		lda #0
		tay
		sta (varbuf),y
		iny
		sta (varbuf),y
deletpc1:
		rts

// append object X to list() and add 1 to its count; X is preserved
// note: does not check the list against its dim size
addpc:
		txa
		pha
		lda lstptr
		sta varbuf
		lda lstptr+1
		sta varbuf+1
		ldy #1
		lda (varbuf),y
		tax
		inx
		txa
		sta (varbuf),y
		stx objnum
		jsr calclst
		sta varbuf
		sty varbuf+1
		ldy #0
		tya
		sta (varbuf),y
		pla
		tax
		iny
		sta (varbuf),y
		rts

// remove the 0 entries from list(): copy each non-zero entry (read through
// zp1) down to the next free slot (varbuf), then store the new count
scandel:
		lda lstptr
		sta varbuf
		sta zp1
		lda lstptr+1
		sta varbuf+1
		sta zp1+1
		ldx #0
		stx deltmp
scandel1:
		inc deltmp
		clc
		lda varbuf
		adc #2
		sta varbuf
		bcc scandel2
		inc varbuf+1
scandel2:
		cpx objnum
		beq scandel5
		inx
		clc
		lda zp1
		adc #2
		sta zp1
		bcc scandel3
		inc zp1+1
scandel3:
		ldy #0
		lda (zp1),y
		iny
		ora (zp1),y
		beq scandel2
scandel4:
		lda (zp1),y
		sta (varbuf),y
		dey
		bpl scandel4
		jmp scandel1
scandel5:
		lda lstptr
		sta varbuf
		lda lstptr+1
		sta varbuf+1
		ldy #1
		lda deltmp
		sec
		sbc #1
		sta (varbuf),y
		sta objnum
		rts

// find the piece type at offset Y of the definition in list()
// carry clear: found (X = position), or the piece is unused (X = 0)
// carry set: not in list()
checkpc:
		ldx #0
		clc
		lda (varbuf+2),y
		sta objtyp
		iny
		lda (varbuf+2),y
		sta objtyp+1
		ora objtyp
		beq checkpc1
		jsr scanlst
checkpc1:
		rts

// function 2: a% = position in list() of an object of type objtyp, or 0
haveobjt:
		jsr getword
		sty objtyp
		stx objtyp+1
		jsr scanlst
		bcc haveobj1
		ldx #0
haveobj1:
		jmp putint

// function 3: empty list(), then add every object whose location is target
// and whose flag bits have none of bitval set (e.g. a user's inventory)
makelist:
		jsr getword
		sty target
		stx target+1
		jsr getword
		sty bitval
		stx bitval+1
		lda lstptr
		sta varbuf
		lda lstptr+1
		sta varbuf+1
		ldy #0
		lda #0
		sta (varbuf),y
		iny
		sta (varbuf),y
		lda objptr
		sta varbuf+2
		lda objptr+1
		sta varbuf+3
		ldx #0
makelst1:
		inx
		clc
		lda varbuf+2
		adc objsiz
		sta varbuf+2
		bcc makelst2
		inc varbuf+3
makelst2:
		ldy #oblocoff
		lda (varbuf+2),y
		iny
		cmp target
		bne makelst3
		lda (varbuf+2),y
		cmp target+1
		bne makelst3
		ldy #obbitoff
		lda (varbuf+2),y
		iny
		and bitval
		bne makelst3
		lda (varbuf+2),y
		and bitval+1
		bne makelst3
		jsr addpc
makelst3:
		cpx objcnt
		bcc makelst1
		rts
