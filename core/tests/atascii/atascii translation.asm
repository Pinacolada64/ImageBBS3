tblatc = $1480 ; $ 80/128 bytes AtASCII -> PetSCII
tblcta = $1500 ; $100/256 bytes PetSCII -> AtASCII
tblcta1= $1600 ; $ 20/ 32 bytes
tblcta2= $1620 ; $ 20/ 32 bytes
tblcta3= $1640 ; $ 20/ 32 bytes

; some notes:
; * so far it seems you can't "un-define" a character translation (to say
;   "don't transmit this byte") by putting a zero byte in its table entry
; * not including tblatc and loading tblcta with &,7,11 prints garbage
;   and locks the BBS up
; * I'm guessing redefining *both* translation tables is causing the problem
;   with backspace and Return

; to save original translation table in VICE monitor:
; s "t.commodore" 00 1480 1680

; C64List4_04.exe "atascii translation.asm" -prg:"t.atascii" -alpha:ascii -ovr

; $1480 to $14FF: ASCII to CBM translation table
; load with &,7,10

{def:use_both_tables}

{ifdef:use_both_tables}
orig tblatc

; ====================================
; AtASCII -> PetSCII translation table
; ====================================

; (from Atari to BBS, I'm assuming)
; Asc-L must be checked to use this table: &,52,16,1

; https://www.atariarchives.org/mapping/appendix10.php
; https://www.atariarchives.org/c3ba/charset_full.php

; PetSCII  character	AtASCII
byte 211 ; heart	0
byte 107 ;		1
byte 103 ;		2
byte 125 ;		3
byte 115 ;		4
byte 110 ;		5
byte 206 ; /		6
byte 205 ; \		7
byte 000 ; r. triangle	8 FIXME
byte 108 ;		9
byte 000 ; l. triangle 10 FIXME
byte 124 ;		11
byte 126 ;		12
byte 155 ; Return	13	; $148d
byte 100 ;		14
byte 123 ;		15
byte 193 ; Sh-A, spade	16
byte 213 ; C= A		17
byte 190 ; -		18
byte 219 ; +		19
byte 126 ; Sh-Q		20 126 was 209
byte 249 ; lower 1/2	21
byte 212 ; shift-T	22
byte 178 ; C= R		23
byte 177 ; C= E		24
byte 161 ; C= K		25
byte 173 ; C= Z		26
byte  27 ; Escape	27 ; not on C= 64
byte 145 ; crsr up	28
byte  17 ; crsr down	29
byte 157 ; crsr left	30
byte  29 ; crsr right	31

; symbols: 32-64
ascii " !{34}#$%&'()*+,-./"
ascii "0123456789:;<=>?"

; 65-90: lowercase in AtASCII is uppercase in PetSCII
ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

; 91-96
; PetSCII ; character	AtASCII

ascii "["		; 91
byte 92 ; backslash	; 92 British pound sign
ascii "]"		; 93
ascii "^"		; 94
byte 164 ; underscore	; 95 C= @: _
byte  96 ; CTRL-.	; 96 not on C=64

; 97-122: uppercase "A-Z" in PetSCII is lowercase "a-z" in AtASCII
byte  97, 98, 99,100,101,102,103,104
byte 105,106,107,108,109,110,111,112
byte 113,114,115,116,117,118,119,120
byte 121,122

byte 123 ; CTRL-;	123
byte 124 ; unknown	124	; FIXME
byte 147 ; CLEAR	125
byte 126 ; DELETE	126	; when Asc-L enabled, Image still outputs "Del Spc Del Del"
byte 127 ; TAB		127

; ==============
;  END OF TABLE
; ==============

{endif}

; ====================================
; PetSCII -> AtASCII translation table
; ====================================

orig tblcta
; $1500 to $15FF: PetSCII to AtASCII translation table
; load with &,7,11

; (from BBS to Atari, I'm assuming)

; Asc-L must be unchecked to use this table: &,52,16,0
; I think this is the table to edit since Asc-L OFF insists on outputting ^T as " ^H^H "

; PetSCII character	AtASCII
byte 0 ; heart		211;
byte 1 ;		107;
byte 2 ;		103;
byte 3 ;		125;
byte 4 ;		115;
byte 5 ;		110;
byte 6 ; /		206;
byte 7 ; \		205;
byte 8 ;	 	000; FIXME
byte 9 ;		108;
byte 10 ; l. triangle 	000; FIXME
byte 11 ;		124;
byte 12 ;		126;
byte 155 ; <Return>	119; TODO: > 1513 +155 to fix CR character?
byte 14 ;		100;
byte 15 ;		123;
byte 16 ; Sh-A, spade	193;
byte 17 ; C= A		213;
byte 18 ; -		190;
byte 19 ; +		219;
byte 126; Sh-Q, ball	209; 20 ATASCII
byte 21 ; lower 1/2	249;
byte 22 ; Sh-T		212;
byte 23 ; C= R		178;
byte 24 ; C= E		177;
byte 25 ; C= K		161;
byte 26 ; C= Z		173;
byte 27 ; Escape	 27; not on C= 64
byte 28 ; crsr up	145;
byte 29 ; crsr down	 17;
byte 30 ; crsr left	157;
byte 31 ; crsr right	 29;

; symbols: 32-64
ascii " !{34}#$%&'()*+,-./"
ascii "0123456789:;<=>?"

; 65-90: AtASCII uppercase is PetSCII lowercase
ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

; 91-95
ascii "["		; 91
byte 92 ; backslash	; 92 British pound sign
ascii "]"		; 93
ascii "^"		; 94
byte  95 ; underscore	; 95 C= @: _
byte  96 ; CTRL-.	; 96 not on C=64

; 97-122: AtASCII lowercase is PetSCII uppercase
ascii "abcdefghijklmnopqrstuvwxyz"

byte 123 ; spade	123
byte 124 ; |		124
byte 147 ; CLEAR	125
byte 126 ; DELETE	126
byte  20 ; TAB		127

; Inverse characters are the same as the characters above,
; but with bit 7 set, adding 128.

; Inverse A-Z

byte 128,129,130,131,132,133,134,135
byte 136,137,138,139,140,141,142,143
byte 144,145,146,147,148,149,150,151
byte 152,153,154

; PetSCII	AtASCII
byte 155	; 155 End Of Line (Return) TODO: > 159b +13 to fix CR?

; no equivalent in PetSCII, keep the same
byte 156 	; 156 Delete line
byte 157	; 157 Insert line
byte 158	; 158 CTRL-Tab
byte 159	; 159 Shift-Tab

byte  32	; 160 Shift-space; visually the same as space)

; These are the same between PetSCII <-> AtASCII until I find out differently

byte 161,162,163,164,165,166,167
byte 168,169,170,171,172,173,174,175
byte 176,177,178,179,180,181,182,183
byte 184,185,186,187,188,189,190,191

; Inverse "@A-Z" (192-218)
byte 192,193,194,195,196,197,198,199
byte 200,201,202,203,204,205,206,207
byte 208,209,210,211,212,213,214,215
byte 216,217,218

; "[\]^_{Shift-Q}a-z" (219-250)
byte 219,220,221,222,223
byte 224,225,226,227,228,229,230,231
byte 232,233,234,235,236,237,238,239
byte 240,241,242,243,244,245,246,247
byte 248,249,250

byte 251 ; Shift-A: spade
byte 252 ; pipe: "|"

byte 253	; 253 Clear screen
byte 254	; 254 Delete character
byte 255	; 148 Insert character
