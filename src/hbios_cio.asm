
	PUBLIC	_hbCioIn, _hbCioIst, _hbCioOut, _hbCioInBlk
	PUBLIC	_hbdInstallCioIn, _hbdCioIn, _hbdCioIn_data
	PUBLIC	_hbdInstallCioOut, _hbdCioOut
	PUBLIC	_hbdCioIn_data

	SECTION CODE

BF_CIO		EQU	$00
BF_CIOIN	EQU	BF_CIO + 0	; CHARACTER INPUT
BF_CIOOUT	EQU	BF_CIO + 1	; CHARACTER OUTPUT
BF_CIOIST	EQU	BF_CIO + 2	; CHARACTER INPUT STATUS
BF_CIOOST	EQU	BF_CIO + 3	; CHARACTER OUTPUT STATUS
BF_CIOINIT	EQU	BF_CIO + 4	; INIT/RESET DEVICE/LINE CONFIG
BF_CIOQUERY	EQU	BF_CIO + 5	; REPORT DEVICE/LINE CONFIG
BF_CIODEVICE	EQU	BF_CIO + 6	; REPORT DEVICE INFO
BF_CIOINBLK	EQU	BF_CIO + 7	;

	;extern byte hbCioIn(hbCioParams* ) __z88dk_fastcall;
_hbCioIn:
	PUSH	IX

	LD	C, (HL)
	INC	HL
	PUSH	HL

	LD	B, BF_CIOIN
	RST	08
	LD	L, A			; RETURN SUCCESS/FAIL

	POP	BC
	LD	A, E
	LD	(BC), A

	POP	IX
	RET


_hbdCioIn:
	PUSH	IX

	LD	IY, 0
_hbdCioIn_data: EQU	$-2

	CALL	0
_hbdCioIn_addr: EQU	$-2

	LD	L, E			; RETURN SUCCESS/FAIL
	LD	H, A
	POP	IX
	RET

; extern uint8_t hbdInstallCioIn(uint8_t driverIndex) __z88dk_fastcall;
_hbdInstallCioIn:
	PUSH	IX

	LD	D, BF_CIOIN
	LD	E, L
	LD	BC, $F801
	RST	08

	LD	(_hbdCioIn_data), DE
	LD	(_hbdCioIn_addr), HL

	LD	L, A
	POP	IX
	RET

	;extern byte hbCioIst(byte driver) __z88dk_fastcall;
_hbCioIst:
	PUSH	IX
	LD	B, BF_CIOIST
  	LD 	C, L			; DRIVER INDEX
	RST	08
	LD	L, A			; RETURN SUCCESS/FAIL
	POP	IX
	RET

	; extern byte hbCioOut(hbCioParams*) __z88dk_fastcall;
_hbCioOut:
	PUSH	IX
	LD	C, (HL)
	INC	HL
	LD	E, (HL)
	LD	B, BF_CIOOUT
	RST	08
	LD	L, A			; RETURN SUCCESS/FAIL
	POP	IX
	RET

; extern uint8_t hbCioOut(char) __z88dk_fastcall;
_hbdCioOut:
	PUSH	IX

	LD	E, L

	LD	IY, 0
_hbdCioOut_data: EQU	$-2

	CALL	0
_hbdCioOut_addr: EQU	$-2

	LD	L, A			; RETURN SUCCESS/FAIL
	POP	IX
	RET

; extern uint8_t hbdInstallCioOut(uint8_t driverIndex) __z88dk_fastcall;
_hbdInstallCioOut:
	PUSH	IX

	LD	D, BF_CIOOUT
	LD	E, L
	LD	BC, $F801
	RST	08

	LD	(_hbdCioOut_data), DE
	LD	(_hbdCioOut_addr), HL

	LD	L, A
	POP	IX
	RET


	;extern uint8_t hbCioInBlk(hbCioParams* ) __z88dk_fastcall;
_hbCioInBlk:
	PUSH	IX

	LD	C, (HL)
	INC	HL
	LD	E, (HL)
	INC	HL
	LD	A, (HL)
	INC	HL
	LD	H, (HL)
	LD	L, A

	LD	B, BF_CIOINBLK
	RST	08
	LD	L, A			; RETURN SUCCESS/FAIL

	POP	IX
	RET

	SECTION IGNORE
