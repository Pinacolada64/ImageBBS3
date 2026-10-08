.var version_number = "3.0"

// image ml equates

.label varbuf = $61
.label chrget = $73
.label chrgot = $79

// rs232 buffer pointers

.label baudof = $299
.label rodbe = $29e
.label rodbs = $29d
.label ridbe = $29b
.label ridbs = $29c
.label enabl = $2a1

// control-codes

.label dish = $08     // disable case-shift
.label ensh = $09     // enable case-shift
.label swlc = $0e     // switch to lower case
.label swuc = $8e     // switch to upper case
.label carriage_return = 13
.label cbm_backspace = 20
.label ascii_backspace = 8
.label ascii_bel = 7
.label ascii_escape = 27
.label ascii_formfeed = 12
.label ascii_ctrl_d = 4
.label ascii_ctrl_x = 24

.label cursor_right = $1d
.label cursor_left =  $9d
.label cursor_up =    $91
.label cursor_down =  $11
.label reverse_on =   $12
.label reverse_off =  $92
.label clear_screen = $93
.label cursor_home = $13
.label british_pound = $5c

.label function_key_2 = 137
.label function_key_5 = 135
.label function_key_6 = 139
.label function_key_7 = 136
.label function_key_8 = 140
 
.label cursor_black =    $90
.label cursor_white =    $05
.label cursor_red =      $1c
.label cursor_cyan =     $9f
.label cursor_purple =   $9c
.label cursor_green =    $1e
.label cursor_blue =     $1f
.label cursor_yellow =   $9e
.label cursor_orange =   $81
.label cursor_brown =    $95
.label cursor_lt_red =   $96
.label cursor_gray1 =    $97
.label cursor_gray2 =    $98
.label cursor_lt_green = $99
.label cursor_lt_blue =  $9a
.label cursor_gray3 =    $9b

.label ten = $dc08
.label scs = $dc09
.label min = $dc0a
.label hrs = $dc0b
//.label carrier = $dd01

.label getin = $ffe4
.label chkout= $ffc9
.label chrout= $ffd2
.label clrchn= $ffcc
.label chkin = $ffc6
.label setnam= $ffbd
.label setlfs= $ffba
.label loadf = $ffd5
.label savef = $ffd8
.label readst= $ffb7
.label romcolors= $e8da
.label chrin = $ffcf
.label setmsg= $ff90
.label openf = $ffc0
.label closef= $ffc3

.label poketok= 151
.label peektok= 194
.label systok = 158
.label loadtok= 147
.label newtok = 162

.label linkprg=$a533
.label makerm1=$b475
.label getbytc=$b79b
.label basic_rom_ptrget1 = $b0e7
.label synerr =$af08
.label getnum =$b7eb
.label ilqerr =$b248
.label retval =$bc49
.label parchk =$aef1
.label getadr =$b7f7
.label retbyt =$b3a2
.label gone1 = $a7e7
.label gone2 = $a7ea
.label eval1 = $ae8d
.label frmnum =$ad8a
.label syscll =$e130
.label comma = $aefd
.label getfile=$e1d4
.label linget = $a96b
.label error = $a437
.label chkcom= $aefd

.label jmptbl = $a000
.label buffer = $ce77
.label buf2 = $ce27
.label fbuf = $ce13

.label death= $1800
.label prgstart = $1801

.label protostart = $c000
.label protoend = $ca80

.label mainline = 1000
.label trapline = 2000
.label imodline = 2300
.label immdline = 3000
.label immdsize = $a00

.label tdisp=$0400+960
.label tcolr=$d800+960
.label sdisp=$0400+920
.label scolr=$d800+920
.label ldisp=$0400+640
.label lcolr=$d800+640
.label adisp=$0400+880
.label acolr=$d800+880

.label fkeybuf = 679 //32
.label emptym0 = 711 //57

.label cassbuff = 828
.label loadflag = 829
.label idlemax =830
.label datebuf = 831 //11
.label daytbl = 842 //24
.label tzoneh = 866
.label tzonem = 867
.label uzoneh = 868
.label uzonem = 869
.label wrapbuf = 870 //80
.label wrapflg = 950
.label modclmn = 951
.label ptrclmn = 952
.label wrapind = 953
.label wrapdmp = 954
.label ptrclm = 955
.label modclm = 956
.label sndtim1 = 957
.label sndtim2 = 958
.label sndwav1 = 959
.label sndwav2 = 960
.label sndwav3 = 961
.label sndrept = 962
.label sndtim1a= 963
.label sndtim2a= 964
.label jiffy = 965
.label blnkflag =966
.label blnkcntr =967
.label ptrlin = 968
.label ptrlinm= 969
.label usrlin = 970
.label usrlinm= 971
.label fredmode= 972
.label montbl = 973 // 36
.label rom0= 1009
.label timeset= 1010
.label flag1 = 1011
.label case1 = 1012
.label temp3 = 1015
.label mline = 1016
.label comm = 1017
.label flags = 1018
.label cline = 1019
.label lines = 1022
.label modes = 1023

.label gc = $c000
.label gchide = $e000
.label gclen = 4

.label ecs = $c000
.label ecshide = $e400
.label ecslen = 10

// screen parameters

.label mcolor = 646
.label mreverse = 199
.label curptr = 209
.label scnpos = 211
.label sline = 214
.label colptr = 243
.label undchr = 206
.label undcol = 647
.label crsrflg = 204
.label crsrmode = 207
.label scnclm = scnpos

.label mjump =$07e8
.label mresult=$07e9
.label mspeed =$07ea
.label mprint =$07eb
//.label mcolor =$07ec
//.label mprtr =$07ed
//.label mreverse=$07ee
.label mci =$07ef
.label mdigits=$07f0
.label carrst =$07f1
.label tsp1 =$07f2
.label tsp2 =$07f3
.label chks =$07f4
.label readmode=$07f6
.label filenum =$07f7
.label tmp5 =$07f8
.label abtchr =$07f9
.label clock =$07fa
.label filetyp =$07fb
.label tmp1 =$07fc
.label tmp2 =$07fd
.label tmp3 =$07fe
.label tmp4 =$07ff

.label local =$d000
.label case =$d001
.label editor =$d002
//.label tsr =$d003
.label llen =$d004
.label someflag = $d005
.label chat =$d006
.label inchat =$d007
.label chatpage=$d008
.label carrier=$d009

// deprecated - use flag_dcd_l
.label mxor =$d00a

.label mkolor =$d00b
.label mupcase =$d00c
.label irqcount=$d00d
.label trans =$d00e
.label index =$d00f

.label tempscn = $1000 //$140
.label tempscn0= tempscn+000
.label tempscn1= tempscn+040
.label tempscn2= tempscn+080
.label tempscn3= tempscn+120
.label tempscn4= tempscn+160
.label tempscn5= tempscn+200
.label tempscn6= tempscn+240
.label tempscn7= tempscn+280
.label tempcol = $1140 //$140
.label tempcol0= tempcol+000
.label tempcol1= tempcol+040
.label tempcol2= tempcol+080
.label tempcol3= tempcol+120
.label tempcol4= tempcol+160
.label tempcol5= tempcol+200
.label tempcol6= tempcol+240
.label tempcol7= tempcol+280
.label emptym3 = $1280 //96

.label idlejif=$12e0
.label idlesec=$12e1
.label idleten=$12e2
.label idlemin=$12e3
.label curdsp =$12e4
.label bar =$12e5
.label tsr2 =$12e6
.label mright =$12e7
.label mleft =$12e8
.label cphase =$12e9
.label key =$12ea
.label shft =$12eb
.label ptrlnfd=$12f0
.label ha577 =$12f1
.label mask =$12f2
.label scnmode=$12f3
.label dflag =$12f4
.label dstat =$12f5
.label cytmp =$12f6
.label interm =$12f7
.label cxsav =$12f8
.label len1 =$12f9
.label passmode=$12fa
.label scnlock =$12fb
.label tmp6 =$12fc
.label tmp7 =$12fd
.label freq =$12fe

.label rs232 = $0800
.label rsinabl = rs232+ $03
.label rsdisab = rs232+ $06
.label rsget = rs232+ $09
.label rsout = rs232+ $0c
.label rsbaud = rs232+ $0f
.label rschar = rs232+ $12

.label chktbl = $1300 //$10
.label bartbl = $1310 //$c0
.label arryptrs=$13d0 //$10
.label daysofm= $13e0 //$0c
.label emptym2= $13ec //$04
.label sndtbl = $13f0 //$60
.label netalrm= $1450 //$30
.label tblatc = $1480 //$80
.label tblcta = $1500 //$100
.label tblcta1= $1600 //$20
.label tblcta2= $1620 //$20
.label tblcta3= $1640 //$20


.label alarmtb= $1660 //$80 (16 entries, 8 bytes per entry)

// struct alarmtb_entry {
//     uint8 enableMode; (0=enable input is a checkmark, nonzero=enable input is a just a byte)
//     uint8 enableInput; // 0=skip
//     uint8 setOutputTimeMsb;
//     uint8 setOutputTimeLsb;
//     uint8 clearOutputTimeMsb;
//     uint8 clearOutputTimeLsb;
//     uint8 unused;
//     uint8 outputCheckmark;
// }

.label date1 = $16e0 //$20
.label lobytes =$1700 //25
.label hibytes =$1719 //25
.label lobytec =$1732 //25
.label hibytec =$174b //25
.label emptym4 =$1764 //28
.label pmodetbl=$1780 //$80

.label ribuf = $0b00
.label robuf = $0b80

.label wedgemem= $0c00
.label trapoff =wedgemem+0
.label trapon = wedgemem+3
.label loadprg =wedgemem+6
.label arraysav=wedgemem+9
.label arrayres=wedgemem+12
.label forcegc =wedgemem+15

// interface page jump table

.label outastrp= $cd00+0
.label usetbl1= $cd00+3
.label swapper= $cd00+6
.label swapagn= $cd00+9
.label trace= $cd00+12
.label chkspcl= $cd00+15
.label convchr= $cd00+18
.label fnvar= $cd00+21
.label fnvar1= $cd00+24
.label evalstr= $cd00+27
.label evalbyt= $cd00+30
.label evalint= $cd00+33
.label evalfil= $cd00+36

.label d1icr = $dc0d
.label timblo= $dc06
.label timbhi= $dc07
.label ciacrb= $dc0f

.label ltk_bnkout= $fc4e
.label ltk_bankin= $fc71
.label ltk_getprt= $9f03
.label ltk_driver= $8045
.label ltk_redbuf= $91e0
.label ltk_clrhdr= $806c
.label ltk_fnfile= $804b
.label ltk_alcont= $807b
.label ltk_mnsext= $809c
.label ltk_output= $8048
.label ltk_activl= $8000
.label ltk_activu= $8001
.label ltk_setlun= $8099

.label hdrblk=$91e0
.label filnam=hdrblk+$00
.label filtyp=hdrblk+$18
.label nbinfl=hdrblk+$10
.label loadad=hdrblk+$1a
.label blmilo=hdrblk+$20
.label nrpblk=hdrblk+$12

// address of modules in the ml file (where they initially load)

.label wedge_load_address = $6c00
.label editor_load_address = $7000
.label gc_load_address = $8000
.label ecs_load_address = $8400
.label struct_load_address = $8e00
.label swap1_load_address = $9400
.label swap2_load_address = $9800
.label swap3_load_address = $9c00

// address of modules when they are executing
// swap modules use protostart if not listed here

.label wedge_exec_address = $0c00
.label editor_exec_address = $1800

// address of modules  when they are "swapped out", waiting to be used

.label editor_swap_address = $d000
.label gc_swap_address = $e000
.label ecs_swap_address = $e400
.label struct_swap_address = $ee00
.label swap1_swap_address = $f400
.label swap2_swap_address = $f800
.label swap3_swap_address = $fc00

// start of the kernal ROM

.label kernal_rom_start = $e000

// 6510 data direction register

.label d6510 = 0

// 6510 data register

.label r6510 = 1

.label r6510_loram =           %00000001 // (out) 1=basic, 0=RAM
.label r6510_hiram =           %00000010 // (out) 1=kernal, 0=RAM
.label r6510_charen =          %00000100 // (out) 1=I/O, 0=Character ROM
.label r6510_cassette_data =   %00001000 // (out) cassette port data output line
.label r6510_cassette_switch = %00010000 // (in) senses the cassette switch
.label r6510_cassette_motor =  %00100000 // (out) 1=motor on, 0=motor off
.label r6510_nc1            =  %01000000 // not connected
.label r6510_nc2            =  %10000000 // not connected


// allow access to character ROM ($33)
.label r6510_char_rom = (r6510_cassette_motor | r6510_cassette_switch | r6510_hiram | r6510_loram)

// allow access to all ram ($34)
.label r6510_all_ram = (r6510_cassette_motor | r6510_cassette_switch | r6510_charen)

// "normal" for this register is $37
.label r6510_normal = (r6510_cassette_motor | r6510_cassette_switch | r6510_charen | r6510_hiram | r6510_loram)

// $allow access to the RAM "underneath" the BASIC ROM ($36)
.label r6510_basic_ram = (r6510_cassette_motor | r6510_cassette_switch | r6510_charen | r6510_hiram)

// variable indices used with usevar/putvar

.label var_an_string = 0
.label var_a_string = 1
.label var_b_string = 2
.label var_d1_string = 4
.label var_lp_float = 15
.label var_pl_float = 16
.label var_rc_float = 17
.label var_sh_float = 18
.label var_ac_integer = 24
.label var_w_string = 27
.label var_p_string = 28
.label var_tr_integer = 29
.label var_a_integer = 30
.label var_b_integer = 31
.label var_dv_integer = 32
.label var_c1_string = 34
.label var_c2_string = 35
.label var_co_string = 36
.label var_kp_integer = 38
.label var_c3_string = 39
.label var_mp_string = 48
.label var_mn_integer = 49

// indices and bit masks for chktbl
.label flag_sys_addr = chktbl + 0
.label flag_sys_l_mask = %00000001 // 0 Sysop available to chat
.label flag_sys_r_mask = %00000010 // 1 Background chat page enable

.label flag_acs_addr = chktbl + 0
.label flag_acs_l_mask = %00000100 // 2 Edit users access
.label flag_acs_r_mask = %00001000 // 3 Block 300 baud callers

.label flag_loc_addr = chktbl + 0
.label flag_loc_l_mask = %00010000 // 4 Local mode (no modem I/O)
.label flag_loc_r_mask = %00100000 // 5 ZZ (pseudo-local) mode

.label flag_tsr_addr = chktbl + 0
.label flag_tsr_l_mask = %01000000 // 6 Edit user's time remaining
.label flag_tsr_r_mask = %10000000 // 7 Prime-time enabled

.label flag_cht_addr = chktbl + 1
.label flag_cht_l_mask = %00000001 // 8 Enter/exit chat mode
.label flag_cht_r_mask = %00000010 // 9 Disable modem input

.label flag_new_addr = chktbl + 1
.label flag_new_l_mask = %00000100 // 10 Disallow new users
.label flag_new_r_mask = %00001000 // 11 Enable screen blanking

.label flag_prt_addr = chktbl + 1
.label flag_prt_l_mask = %00010000 // 12 Print spooling
.label flag_prt_r_mask = %00100000 // 13 Print log entries

.label flag_uxd_addr = chktbl + 1
.label flag_uxd_l_mask = %01000000 // 14 Disable U/D section
.label flag_uxd_r_mask = %10000000 // 15 300 baud U/D lockout

.label flag_asc_addr = chktbl + 2
.label flag_asc_l_mask = %00000001 // 16 ASCII translation
.label flag_asc_r_mask = %00000010 // 17 Line feed after carriage return

.label flag_ans_addr = chktbl + 2
.label flag_ans_l_mask = %00000100 // 18 ANSI color enabled
.label flag_ans_r_mask = %00001000 // 19 ANSI graphics enabled

.label flag_exp_addr = chktbl + 2
.label flag_exp_l_mask = %00010000 // 20 Expert mode enabled
.label flag_exp_r_mask = %00100000 // 21 Disallow double calls

.label flag_unv_addr = chktbl + 2
.label flag_unv_l_mask = %01000000 // 22 No immediate U/D credits
.label flag_unv_r_mask = %10000000 // 23 Allow auto-logoff

.label flag_trc_addr = chktbl + 3
.label flag_trc_l_mask = %00000001 // 24 On-screen trace enable
.label flag_trc_r_mask = %00000010 // 25 Undefined

.label flag_bel_addr = chktbl + 3
.label flag_bel_l_mask = %00000100 // 26 Local bells enabled
.label flag_bel_r_mask = %00001000 // 27 Local beeps disabled

.label flag_net_addr = chktbl + 3
.label flag_net_l_mask = %00010000 // 28 NetMail enable
.label flag_net_r_mask = %00100000 // 29 NetMail trigger

.label flag_mac_addr = chktbl + 3
.label flag_mac_l_mask = %01000000 // 30 Macros on/off
.label flag_mac_r_mask = %10000000 // 31 MCI disable in editor

.label flag_chk_addr = chktbl + 4
.label flag_chk_l_mask = %00000001 // 32 Enable MailCheck at logon
.label flag_chk_r_mask = %00000010 // 33 Excessive chat logoff

.label flag_mor_addr = chktbl + 4
.label flag_mor_l_mask = %00000100 // 34 More prompt on
.label flag_mor_r_mask = %00001000 // 35 More prompt not available

.label flag_frd_addr = chktbl + 4
.label flag_frd_l_mask = %00010000 // 36 Full-color read disable
.label flag_frd_r_mask = %00100000 // 37 Undefined

.label flag_sub_addr = chktbl + 4
.label flag_sub_l_mask = %01000000 // 38 Messages bases closed
.label flag_sub_r_mask = %10000000 // 39 Files section closed

.label flag_res_addr = chktbl + 5
.label flag_res_l_mask = %00000001 // 40 System reserved
.label flag_res_r_mask = %00000010 // 41 Network reserved

.label flag_mnt_addr = chktbl + 5
.label flag_mnt_l_mask = %00000100 // 42 Undefined
.label flag_mnt_r_mask = %00001000 // 43 Modem answer disabled

.label flag_mnu_addr = chktbl + 5
.label flag_mnu_l_mask = %00010000 // 44 Is user in menu mode?
.label flag_mnu_r_mask = %00100000 // 45 Are menus available on BBS?

.label flag_h2e_addr = chktbl + 5
.label flag_h2e_l_mask = %01000000 // 46 Undefined
.label flag_h2e_r_mask = %10000000 // 47 Undefined

.label flag_h38_addr = chktbl + 7
.label flag_h38_l_mask = %00000001 // 56 ($38) Used for something in basic
.label flag_h38_r_mask = %00000010 // 57 ($39) Unknown

.label flag_dcd_addr = chktbl + 7
.label flag_dcd_l_mask = %00000100 // 58 ($3a) invert DCD
.label flag_dcd_r_mask = %00001000 // 59 ($3b)

.label flag_dsr_addr = chktbl + 7
.label flag_dsr_l_mask = %00010000 // 60 ($3c) DCD/DSR select (on = DSR, off=DCD)
.label flag_dsr_r_mask = %00100000 // 61 ($3d) enable RX/TX windows

// editor input flags

.label editor_allow_cursor_controls =   %00000001 // allow cursor movement and color characters in input
.label editor_dot_on_column_one =       %00000010 // dot on column one exits input
.label editor_show_prompt =             %00000100 // show prompt
.label editor_allow_mci =               %00001000 // allow mci command character input
.label editor_word_wrap =               %00010000 // word wrap enabled
.label editor_edit_mode =               %00100000 // edit mode
.label editor_ignore_time_remaining =   %01000000 // ignore time remaining
.label editor_backspace_on_column_one = %10000000 // backspace on column one exits input

.label passmode_off       = %00000000 // all password flags off
.label passmode_show_mask = %00000001 // password mask enabled for output
.label passmode_no_output = %00000010 // no output
