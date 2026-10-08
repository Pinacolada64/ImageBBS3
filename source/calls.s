inline:
		lda #00
		.byte $2c
clrarr:
		lda #11
		.byte $2c
sound:
		lda #25
		.byte $2c
inline0:
		lda #63
		.byte $2c
convstr:
		lda #64
		.byte $2c
convert:
		lda #65
		jmp usetbl1
copyrite:
		lda #67
		jsr usetbl1
		jmp outastr

// call a jump table routine
// this might be just directly in RAM, or it might require swapping
// passed address in x (hi),y (lo)

caller:
		sty calljmp+1

// if the module is already the active module, then we don't need to swap it

		cpx callpage
		beq caller2

// if no other module is swapped in, then we can just swap and call

		lda callpage
		beq caller1

// swap the new module into memory if another one is already present

// swap the previous module back out to it's swap-out location

		jsr callswap

// call the new module

		jsr caller1

// swap the previous module back in when finished

		jsr callswap

		lda 780
		rts

// swap the new module in, call it, then swap it back out
// preserving the old module
// on input, new module page is in X register

caller1:
		lda callpage
		pha
		stx callpage
		jsr callswap
		jsr caller2
		jsr callswap
		pla
		sta callpage
		lda 780
		rts

// call the target with the original register values

caller2:
		lda 780
		ldx 781
		ldy 782

// self modifying code sets the low byte of the jump

calljmp:
		jsr protostart
		sta 780
		stx 781
		sty 782
		rts

callswap:

// preserve registers

		pha
		txa
		pha
		tya
		pha

// determine the size of the module being swapped
// this code assumes the order of the modules
// TODO split out each module, fail if unknown value used

		lda callpage

 // swap1, swap2, swap3 must be the same size

		ldx #>swap1_module_size
		cmp #>swap1_swap_address
		bcs callswp1

		ldx #>struct_module_size
		cmp #>struct_swap_address
		bcs callswp1

		ldx #>ecs_module_size
		cmp #>ecs_swap_address
		bcs callswp1

		ldx #gc_module_size

// swap the module to the execution address

callswp1:
		ldy #>protostart
		jsr swapper

// restore all registers

		pla
		tay
		pla
		tax
		pla
		rts

callpage:
		.byte 0
calltemp:
		.byte 0
