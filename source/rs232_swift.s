#import "equat.s"

* = $0800 "rs232_swift.prg"

// .label baudof = $299
// .label rodbe = $29e
// .label rodbs = $29d
// .label ridbe = $29b
// .label ridbs = $29c
// .label enabl = $2a1

.label rstkey = $fe56
.label norest = $fe72
.label nmiexit = $febc
.label findfn = $f30f
.label devnum = $f31f
.label nofile = $f701

.label io1=$de00
.label io2=$df00
.label m6551_port = io1
.label m6551_status = m6551_port + 1
.label m6551_command = m6551_port + 2
.label m6551_control = m6551_port + 3

// command port values

.label m6551_cmd_dtr_high =       %00000000 // high is not asserted.
.label m6551_cmd_dtr_low =        %00000001 // low is asserted
.label m6551_cmd_rxint_enabled =  %00000000
.label m6551_cmd_rxint_disabled = %00000010
.label m6551_cmd_tx_0 =           %00000000 // interrupt disabled, RTS high (not asserted)
.label m6551_cmd_tx_1 =           %00000100 // interrupt enabled, RTS low (asserted)
.label m6551_cmd_tx_2 =           %00001000 // interrupt disabled, RTS low (asserted)
.label m6551_cmd_tx_3 =           %00001100 // interrupt disabled, RTS low (asserted), transmit break
.label m6551_cmd_echo_off =       %00000000
.label m6551_cmd_echo_on =        %00010000
.label m6551_cmd_parity_none =    %00000000
.label m6551_cmd_parity_odd =     %00100000
.label m6551_cmd_parity_even =    %01100000
.label m6551_cmd_parity_mark =    %10100000
.label m6551_cmd_parity_space =   %11100000

// interrupts disabled
.label comint_none = m6551_cmd_dtr_low | m6551_cmd_rxint_disabled | m6551_cmd_tx_2 | m6551_cmd_echo_off | m6551_cmd_parity_none

// receive interrupt enabled, transmit interrupt disabled
.label comint_rx =  m6551_cmd_dtr_low | m6551_cmd_rxint_enabled | m6551_cmd_tx_2 | m6551_cmd_echo_off | m6551_cmd_parity_none

// all interrupts enabled
.label comint_rxtx = m6551_cmd_dtr_low |  m6551_cmd_rxint_enabled | m6551_cmd_tx_1 | m6551_cmd_echo_off | m6551_cmd_parity_none

// unassert DTR - tells the device we are not online
// also disables interrupts, since they should not happen anyway
.label comdtr0 = m6551_cmd_dtr_high | m6551_cmd_rxint_disabled | m6551_cmd_tx_2 | m6551_cmd_echo_off | m6551_cmd_parity_none

// unassert RTS - tells the device to stop sending
// The 6551 disables tx interrupts when you unassert RTS
// This setting also disables rx interrupts, since they should not happen anyway
.label comrts0 = m6551_cmd_dtr_low |  m6551_cmd_rxint_disabled | m6551_cmd_tx_0 | m6551_cmd_echo_off | m6551_cmd_parity_none

.label m6551_stat_int =       %10000000 // interrupt has occurred
.label m6551_stat_dsr =       %01000000 // Data Set Ready: 0=DSR low (ready), 1=DSR high (not ready)
.label m6551_stat_dcd =       %00100000 // Carrier detect: 0=DCD low (detected), 1=DCD high (not detected)
.label m6551_stat_tdr_empty = %00010000 // transmit data register empty: 0=not empty, 1=empty
.label m6551_stat_rdr_full =  %00001000 // receive data register full: 0=not full, 1=full
.label m6551_stat_overrun =   %00000100 // overrun: 0=no overrun, 1=overrun detected
.label m6551_stat_framing =   %00000010 // framing error: 0=no error, 1=error detected
.label m6551_stat_parity =    %00000001 // parity error: 0=no error, 1=error detected

.label imagecd0 = %00000000 //none
.label imagecd1 = %00010000 //carrier

// when there are this many or more bytes in the input buffer, disable rx
.label upper_flow_control_threshold = 120

// when there are less than this many bytes in the input buffer, enable rx
.label lower_flow_control_threshold = 100

.label overrun_indicator = tdisp + 29
.label loading_indicator = tdisp + 30
.label flow_control_indicator = tdisp + 32
.label interrupt_disabled_indicator = tdisp + 33

first:

xx00:
		jmp setup
xx03:
		jmp inable
xx06:
		jmp disabl
xx09:
		jmp rsget_entry
xx0c:
		jmp rsout_entry
xx0f:
		jmp setbaud

bauds:
		.byte %00010101 // 0300
		.byte %00010110 // 0600
		.byte %00010111 // 1200
		.byte %00011000 // 2400
		.byte %00011010 // 4800
		.byte %00011100 // 9600
		.byte %00011110 //19200
		.byte %00011111 //38400

// shadow command byte
// this is the last value set on the port
// which should be restored after disabling then enabling interrupts

shcomm:
		.byte comint_rx

status_shadow:
		.byte 0

vectbl:

oldnmi:
		.byte $18
		.word nmi64
oldopn:
		.byte $1a
		.word nopen
oldcls:
		.byte $1c
		.word nclose
oldchk:
		.byte $1e
		.word nchkin
oldcho:
		.byte $20
		.word nchkout
oldclr:
		.byte $22
		.word nclrch
oldchr:
		.byte $24
		.word nchrin
//oldout:
//		.byte $26
//		.word nchrout
oldget:
		.byte $2a
		.word ngetin
oldload:
		.byte $30
		.word nload
oldsave:
		.byte $32
		.word nsave

		.byte 0

setup:

// drop DTR initially

		lda #comint_none
		sta m6551_command

		ldx #0
		lda #3
		sta 21
setup1:
		lda vectbl,x
		beq setup3
		sta 20

// replace index with a "JMP" instruction

		lda #$4c
		sta vectbl,x
		inx

		ldy #0
setup2:

// swap original vector with new value

		lda vectbl,x
		pha
		lda (20),y
		sta vectbl,x
		pla
		sta (20),y
		iny
		inx
		cpy #2
		bcc setup2
		jmp setup1

setup3:

// do a "soft" reset of the chip

		lda #0
		sta m6551_status

// set initial command register settings to "rx int enabled, tx int disabled"

		lda #comint_rx
		sta shcomm

// write the command register

		jsr inable

// set the image carrier detected bit based on DCD (should clear it)

		jsr setcarr

// set default bit rate to 1200

		lda #2
		jmp setbaud

// set the carrier flag based on DCD
// expected to only use A and Y

setcarr:
		lda flag_dsr_addr
		and #flag_dsr_l_mask
		beq setcarr_dcd

setcarr_dsr:
		lda status_shadow
		and #m6551_stat_dsr
		beq setcarr1

// no carrier
setcarr0:
		lda #imagecd0
		sta carrier
		rts

setcarr_dcd:
		lda status_shadow
		and #m6551_stat_dcd
		bne setcarr0

// carrier present
setcarr1:
		lda #imagecd1
		sta carrier
		rts

// interrupt routine

nmi64:
		pha
		txa
		pha
		tya
		pha
		cld

// disable further interrupts
// if we clear an interrupt source then another happens,
// then the new interrupt can interrupt this handler

		lda #comint_none
		sta m6551_command

		lda m6551_status
		sta status_shadow
		and #m6551_stat_int
		beq notacia

// handle interrupt sources

		jsr setcarr
		jsr rxint

// enable interrupts

		lda shcomm
		sta m6551_command

		pla
		tay
		pla
		tax
		pla
		rti

// the interrupt wasn't from the ACIA, so it must have come from the "restore" key
notacia:
		ldy #0
		jmp rstkey

// check for character
// expected to only use A and Y

rxint:
		lda status_shadow
		and #m6551_stat_rdr_full
		beq rxint_no_receive

// a byte is available

		lda m6551_port
		ldy ridbe
		sta ribuf,y
		iny
		tya
		and #127
		cmp #ridbs
		beq rxint_buffer_overrun
		sta ridbe
		jmp rxint_no_receive

rxint_buffer_overrun:

		lda #comrts0
		sta shcomm
		lda #$cf // reverse uppercase O
		sta overrun_indicator

		rts

rxint_no_receive:

// Check if the buffer is close to full
		lda ridbe
		sec
		sbc ridbs
		and #127
		cmp #upper_flow_control_threshold
		bcc rxint_done

rsint_stop_flow:
		lda #comrts0
		sta shcomm
		lda #$c6 // reverse capital F
		sta flow_control_indicator

rxint_done:
		rts

// disable interrupts

disabl:
		php
		pha
		lda #$c9 // reverse capital I
		sta interrupt_disabled_indicator
		lda #comint_none
		sta m6551_command
		pla
		plp
		rts

// enable interrupts (restore to shadow value)

inable:
		php
		pha
		lda #$a0 // reverse space
		sta interrupt_disabled_indicator
		lda shcomm
		sta m6551_command
		pla
		plp
		rts

// rs232 bsout

rsout_entry:

// stash for later

		sta $9e
		sty $97

// update on-screen buffers

		ldy scnmode
		bne rsout_skip_screen

		lda flag_dsr_addr
		and #flag_dsr_r_mask
		beq rsout_skip_screen

		ldy #0
outdisp:
		lda sdisp+30,y
		sta sdisp+29,y
		iny
		cpy #9
		bcc outdisp
		lda $9e
		sta sdisp+38

rsout_skip_screen:
		lda #comint_none
		sta m6551_command

rsout_blocking:
		lda m6551_status
		sta status_shadow

		jsr setcarr
		jsr rxint

		lda status_shadow
		and #m6551_stat_tdr_empty
		beq rsout_blocking

		lda $9e
		sta m6551_port

		lda shcomm
		sta m6551_command

// exit and restore registers

		jmp rsget_done

xtmp:
		.byte 0

nosuch:
		jmp nofile

nchkin:
		stx xtmp
		jsr findfn
		bne nosuch
		jsr devnum
		ldx xtmp
		lda $ba
		cmp #2
		bne nchkin1
		sta $99
		clc
		jmp inable

nchkin1:
		jsr disabl
		jsr oldchk
		jmp inable

nchkout:
		stx xtmp
		jsr findfn
		bne nosuch
		jsr devnum
		ldx xtmp
		lda $ba
		cmp #2
		bne nchkout1
		sta $9a
		clc
		jmp inable

nchkout1:
		jsr disabl
		jsr oldcho
		jmp inable

ngetin:
		pha
		lda $9a
		cmp #2
		bne notget
		pla

// ** rs232 getin

rsget_entry:

// stash for later

		sta $9e
		sty $97

// if buffer is empty, then we're done

		ldy ridbs
		cpy ridbe
		beq rsget_no_char

		lda ribuf,y
		sta $9e
		iny
		bpl rsget_no_wrap
		ldy #0
rsget_no_wrap:
		sty ridbs

// update on screen buffers

		ldy scnmode
		bne rsget_skip_screen

		lda flag_dsr_addr
		and #flag_dsr_r_mask
		beq rsget_skip_screen

		ldy #0
inpdisp:
		lda sdisp+2,y
		sta sdisp+1,y
		iny
		cpy #9
		bcc inpdisp
		lda $9e
		sta sdisp+10

rsget_skip_screen:
		lda ridbe
		sec
		sbc ridbs
		and #127
		cmp #lower_flow_control_threshold
		bcs rsget_got_char

rsget_enable_rx_int:
		lda #comint_rx
		sta shcomm
		sta m6551_command
		lda #$a0 // reverse space
		sta flow_control_indicator

rsget_got_char:
		clc
		jmp rsget_done

rsget_no_char:
		sec

rsget_done:

		ldy $97
		lda $9e
		rts

notget:
		pla
		jsr disabl
		jsr oldget
		jmp inable

setbaud:
		cmp #254
		bcc setbaud3
		beq setbaud1
		lda shcomm
		jmp setbaud2
setbaud1:
		lda #comdtr0
setbaud2:
		sta m6551_command
		rts
setbaud3:
		and #7
		tay
		lda bauds,y
		sta m6551_control
		rts

//nchrout:
//		jsr disabl
//		jsr oldout
//		jmp inable

nopen:
		jsr disabl
		jsr oldopn
		jmp inable

nclose:
		jsr disabl
		jsr oldcls
		jmp inable

nclrch:
		jsr disabl
		jsr oldclr
		jmp inable

nchrin:
		jsr disabl
		jsr oldchr
		jmp inable

nload:
		jsr disabl
		pha
		lda #$cc // reverse uppercase L
		sta loading_indicator
		pla
		jsr oldload
		pha
		lda #$a0 // reverse space
		sta loading_indicator
		pla
		jmp inable

nsave:
		jsr disabl
		pha
		lda #$cc // reverse uppercase L
		sta loading_indicator
		pla
		jsr oldsave
		pha
		lda #$a0 // reverse space
		sta loading_indicator
		pla
		jmp inable

last:
