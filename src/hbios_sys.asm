
	PUBLIC	_hbSysGetTimer16, _hbSysGetVda, _hbSysBankCopy, _hbSysIntInfo, _hbSysIntSet, _hbSysGetCioFn, _hbDirect, _hbSysGetBnkInfo, _hbGetCurrentBank, _hbSetCurrentBank

	SECTION CODE

include "hbios_sys.inc"

BIOSBID:	DW	0

	;extern uint16_t _hbSysGetCioFn(hbSysGetFunc*) __z88dk_fastcall;

_hbSysGetCioFn:
	PUSH	IX

	LD	D, (HL)		; FUNCTION CODE
	INC	HL
	LD	E, (HL)		; DRIVER UNIT
	INC	HL
	PUSH	HL

	LD	BC, $F801
	RST	08

	LD	B, H
	LD	C, L		; BC = DRIVER FUNCTION ADDRESS
	POP	HL		; HL = RETURN STRUCT PTR

	LD	(HL), C		; SAVE DRIVER FUNCTION ADDRESS
	INC	HL
	LD	(HL), B
	INC	HL

	LD	(HL), E		; SAVE DRIVER DATA ADDRESS
	INC	HL
	LD	(HL), D

	LD	L, A		; SET RETURN CODE
	POP	IX
	RET

;extern uint8_t hbSysGetBnkInfo(hbSysGetBnkInfoParams*) __z88dk_fastcall;

_hbSysGetBnkInfo:
	PUSH	IX

	PUSH	HL

	LD	BC, $0F8F2	; HBIOS SYSGET, Bank Info
	RST	08		; do it

	POP	HL
	LD	(HL), D
	INC	HL
	LD	(HL), E

	LD	L, A
	POP	IX
	RET


; extern uint8_t hbGetCurrentBank();
_hbGetCurrentBank:
	LD	A, (HB_CURBNK)
	LD	L, A
	RET

;extern void hbSetCurrentBank(uint8_t) __z88dk_fastcall;
_hbSetCurrentBank:
	LD	A, l
	JP	HBX_BNKSEL

;extern uint8_t hbDirect(hbSysGetFunc*) __z88dk_fastcall;
_hbDirect:
	PUSH	IX

	LD	IX, _hbDirectRet	; set return address
	PUSH	IX

	INC	HL
	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL
	PUSH	DE
	POP	IX

	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	PUSH	DE
	POP	IY

	JP	(IX)

_hbDirectRet:
	LD	L, A
	POP	IX
	RET


	;extern uint16_t hbSysGetTimer() __z88dk_fastcall;
_hbSysGetTimer16:
	PUSH	IX
	LD	BC, 0xF8D0
	RST	08

	POP	IX
	RET

; typedef struct  {
;   uint8_t func;
;   uint8_t unit;
;   void* driverFnAddr;
;   void* driverDataAddr;
; } hbiosDriverEntry;
; byte hbSysGetVda(hbiosDriverEntry* pData) __z88dk_fastcall

_hbSysGetVda:
	PUSH	IX

	LD	BC, SYSGET_VDAFN
	LD	D, (HL)
	INC	HL		; VDAFN
	LD	E, (HL)		; UNIT
	INC	HL
	PUSH	HL

	RST	08		; DE NOW CONTAINS ADDR OF TMS DATA/CONFIG

	PUSH	HL
	POP	BC
	POP	HL
	PUSH	AF

	LD	A, C
	LD	(HL), A

	INC	HL
	LD	A, B
	LD	(HL), A

	INC	HL
	LD	A, E
	LD	(HL), A

	INC	HL
	LD	A, D
	LD	(HL), A

	POP	AF
	LD	L, A
	LD	H, 0
	POP	IX
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; typedef struct {
;   uint8_t destBank;
;   uint8_t sourceBank;
;   uint16_t byteCount;
;   void* destAddr;
;   void* sourceAddr;
; } hbiosBankCopy;
; uint8_t hbSysBankCopy(hbiosBankCopy* pData)  __z88dk_fastcall;

_hbSysBankCopy:
	PUSH	IX

	LD	B, BF_SYSSETCPY
	LD	D, (HL)
	INC	HL
	LD	E, (HL)
	INC	HL
	LD	A, (HL)
	INC	HL
	PUSH	HL
	LD	H, (HL)
	LD	L, A

	RST	08		;
	POP	HL
	OR	A
	JR	NZ, _hbSysBankCopyErr

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	INC	HL
	LD	A, (HL)
	INC	HL
	LD	H, (HL)
	LD	L, A
	LD	B, BF_SYSBNKCPY
	RST	08

_hbSysBankCopyErr:
	LD	L, A
	LD	H, 0
	POP	IX
	RET



; typedef struct {
;   uint8_t sizeOfInterruptVectorTable;
;   uint8_t interruptMode;
; } hbSysParams;
; extern uint8_t hbSysIntInfo(hbSysParams*) __z88dk_fastcall;
_hbSysIntInfo:
	PUSH	IX

	LD	BC, BF_SYSINT * 256 + BF_SYSINT_INFO
	PUSH	HL
	RST	08
	POP	HL

	LD	(HL), E
	INC	HL
	LD	(HL), D
	LD	L, A

	POP	IX
	RET


_hbSysIntSet:
	PUSH	IX

	LD	BC, BF_SYSINT * 256 + BF_SYSINT_SET

	LD	E, (HL)
	INC	HL
	LD	A, (HL)
	INC	HL
	PUSH	HL
	LD	H, (HL)
	LD	L, A

	RST	08
	POP	BC

	EX	DE, HL
	POP	HL
	INC	HL
	LD	(HL), E
	INC	HL
	LD	(HL), D

	LD	L, A

	POP	IX
	RET

	SECTION IGNORE
