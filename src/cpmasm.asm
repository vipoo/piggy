; LOAD FILE
; NAME AT DE
; DESTINATION AT HL

	SECTION CODE

	PUBLIC	_fOpen, _fDmaOff, _fRead, _fSize, _fClose, _fRead, _chk, _fMake, _fWrite, _fDelete
	; PUBLIC _drvAllReset, _drvReset, _drvFree
	EXTERN	__Exit

RESTART	EQU	$0000		; CP/M RESTART VECTOR
BDOS	EQU	$0005		; BDOS INVOCATION VECTOR

FCB		EQU	$5C		; Location of default FCB
DRV_ALLRESET	EQU	13
DRV_RESET	EQU	25
DRV_FREE	EQU	39
F_OPEN		EQU	15
F_CLOSE		EQU	16
F_DELETE	EQU	19
F_READ		EQU	20
F_WRITE		EQU	21
F_MAKE		EQU	22
F_DMAOFF	EQU	26
F_SIZE		EQU	35

_chk:
	ld	a, h
	or	a, l
	ret	Z
	ld	hl,0x0001
	jp	__Exit


; int fOpen(const char* fcb) __z88dk_fastcall
_fDelete:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_DELETE		; CPM Open File function
	CALL	BDOS
	LD	L, A
	LD	H, 0
	POP	IX
	RET

; int fOpen(const char* fcb) __z88dk_fastcall
_fMake:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_MAKE		; CPM Open File function
	CALL	BDOS
	LD	L, A
	LD	H, 0
	POP	IX
	RET

; int fOpen(const char* fcb) __z88dk_fastcall
_fOpen:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_OPEN		; CPM Open File function
	CALL	BDOS
	LD	L, A
	POP	IX
	RET

; int fDmaOff(void* dest) __z88dk_fastcall
_fDmaOff:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_DMAOFF		; CPM Set DMA function
	CALL	BDOS
	LD	L, A
	LD	H, 0
	POP	IX
	RET

; int fRead(const char* fcb) __z88dk_fastcall
_fRead:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_READ		; CPM Open File function
	CALL	BDOS
	LD	l, A
	LD	H, 0
	POP	IX
	RET

; int fSize(const char* fcb) __z88dk_fastcall
_fSize:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_SIZE		; CPM Open File function
	CALL	BDOS
	POP	IX
	RET

; int fWrite(const char* fcb) __z88dk_fastcall
_fWrite:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_WRITE		; CPM Open File function
	CALL	BDOS
	POP	IX
	RET

; int fClose(const char* fcb) __z88dk_fastcall
_fClose:
	PUSH	IX
	LD	E, L
	LD	D, H
	LD	C, F_CLOSE		; CPM Open File function
	CALL	BDOS
	POP	IX
	RET

; _drvAllReset:
; 	PUSH	IX
; 	LD	C, DRV_ALLRESET
; 	CALL	BDOS
; 	LD 	L, A
; 	LD	H, 0
; 	POP	IX
; 	RET

; _drvReset:
; 	PUSH	IX
; 	LD	C, DRV_RESET
; 	EX	DE, HL
; 	CALL	BDOS
; 	LD	L, A
; 	LD	H, 0
; 	POP	IX
; 	RET

; _drvFree:
; 	PUSH	IX
; 	LD	C, DRV_FREE
; 	EX	DE, HL
; 	CALL	BDOS
; 	LD	L, A
; 	LD	H, 0
; 	POP	IX
; 	RET

	SECTION IGNORE
