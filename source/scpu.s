//********************************
//* SuperCPU speed for a protocol *
//********************************

// #import into a transfer protocol (punter.s, xmodem.s), after its entry
// point (protostart). RS-232 needs the C64's own speed, so a protocol's
// transfer functions run at 1 MHz:
//
//		jsr scpu_slow	// 1 MHz
//		...transfer...
//		jsr scpu_turbo	// turbo on again
//
// Both do nothing unless there is a SuperCPU (lightbar checkmark 52, $34)
// and turbo mode is on (checkmark 53, $35); the transfer doesn't change the
// checkmarks, so the same test tells scpu_turbo to turn it back on. Each
// checkmark is read with &,52,x,5 (via usetbl1), which returns the
// checkmark's bit in the accumulator: nonzero if it is on.
// A, X and Y are kept.

scpu_slow:
		jsr scpu_check
		beq scpu_slow1
		sta scpu_1mhz		// any value
scpu_slow1:
		rts

scpu_turbo:
		jsr scpu_check
		beq scpu_turbo1
		sta scpu_20mhz		// any value
scpu_turbo1:
		rts

// Z clear if checkmarks 52 and 53 are both on
scpu_check:
		sta scpu_a
		stx scpu_x
		sty scpu_y
		lda #52			// &,52,$34,5
		ldx #$34
		ldy #5
		jsr usetbl1
		beq scpu_check1
		lda #52			// &,52,$35,5
		ldx #$35
		ldy #5
		jsr usetbl1
scpu_check1:
		php
		lda scpu_a
		ldx scpu_x
		ldy scpu_y
		plp
		rts

scpu_a:
		.byte 0
scpu_x:
		.byte 0
scpu_y:
		.byte 0
