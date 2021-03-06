
	PUBLIC	_installSioHandler, _uninstallSioHandler, _sioIn, _sioIst, _sioCfg, _sioOut, _sioCount, _dataLoss, _sioRtsOn, _sioRtsOff
	EXTERN 	_hbdCioIn_data
	SECTION CODE

include "hbios_sys.inc"

SIO_RTSON	EQU	$EA
SIO_RTSOFF	EQU	$E8

SIO0A_BUF	EQU	$8000		;	SIO_BUFSZ,0	; RECEIVE RING BUFFER

SIO_BUFSZ	EQU	255		; RECEIVE BUFFER SIZE
BUFF_HIGH_MARK	EQU	240		; POINT TO TURN RTS OFF
BUFF_LOW_MARK	EQU	128		; POINT TO TURN RTS ON

_installSioHandler:
	PUSH	IX

	LD	BC, BF_SYSINT * 256 + BF_SYSINT_SET
	LD	E, 0
	LD	HL, SIO_INTRCV
	RST	08
	LD	(_prevIntHndlr), HL

	LD	L, A

	LD	A, (sioDataPort)
	LD	(sioDataPortRef1), A
	LD	(sioDataPortRef2), A

	LD	A, (sioCmdPort)
	LD	(sioCmdPortRef1), A
	LD	(sioCmdPortRef2), A
	LD	(sioCmdPortRef3), A
	LD	(sioCmdPortRef4), A
	LD	(sioCmdPortRef5), A
	LD	(sioCmdPortRef6), A
	LD	(sioCmdPortRef7), A
	LD	(sioCmdPortRef8), A
	LD	(sioCmdPortRef9), A
	LD	(sioCmdPortRefA), A
	LD	(sioCmdPortRefB), A
	LD	(sioCmdPortRefC), A

	DI
	LD	C, A
	LD	A, 5			; RTS IS IN WR5
	OUT	(C), A			; ADDRESS WR5
	LD	A, SIO_RTSON		; VALUE TO CLEAR RTS
	OUT	(C), A
	EI

	POP	IX
	RET

_uninstallSioHandler:
	PUSH	IX

	LD	BC, BF_SYSINT * 256 + BF_SYSINT_SET
	LD	E, 0
	LD	HL, (_prevIntHndlr)
	RST	08

	LD	L, A
	POP	IX
	RET


_handler:
SIO_INTRCV:
	; CHECK TO SEE IF SOMETHING IS ACTUALLY THERE
	XOR	A			; A := 0
	OUT	(0), A			; ADDRESS RD0
sioCmdPortRef1:	EQU	$-1
	IN	A, (0)			; GET RD0
sioCmdPortRef2:	EQU	$-1
	AND	$01			; ISOLATE RECEIVE READY BIT
	JR	NZ, SIO_INTRCV1		; NOTHING AVAILABLE ON CURRENT CHANNEL
	JP	0
_prevIntHndlr:	EQU	$-2


SIO_INTRCV1:
	; RECEIVE CHARACTER INTO BUFFER
	IN	A, (0)
sioDataPortRef1: EQU	$-1
	LD	B, A

	LD	HL, SIO0A_CNT		; SET HL TO
	LD	A, (HL)			; GET COUNT
	CP	SIO_BUFSZ		; COMPARE TO BUFFER SIZE
	JR	NZ, SIO_INTRCV2a		; BAIL OUT IF BUFFER FULL, RCV BYTE DISCARDED

	LD	A, $FF
	LD	(_dataLoss), A
	JR	SIO_INTRCV4

SIO_INTRCV2a:
	INC	A			; INCREMENT THE COUNT
	LD	(HL), A			; AND SAVE IT
	CP	BUFF_HIGH_MARK			; BUFFER GETTING FULL?
	JR	NZ, SIO_INTRCV2		; IF NOT, BYPASS CLEARING RTS

	; RTS OFF
	LD	A, 5			; RTS IS IN WR5
	OUT	(0), A			; ADDRESS WR5
sioCmdPortRef3:	EQU	$-1
	LD	A, SIO_RTSOFF		; VALUE TO CLEAR RTS
	OUT	(0), A			; DO IT
sioCmdPortRef4:	EQU	$-1



SIO_INTRCV2:
	LD	hl, (sioHead)
	LD	(HL),B			; SAVE CHARACTER RECEIVED IN BUFFER AT HEAD
	INC	L

SIO_INTRCV3:
	ld	(sioHead), HL
	; CHECK FOR MORE PENDING...
	XOR	A			; A := 0
	OUT	(0), A			; ADDRESS RD0
sioCmdPortRef5:	EQU	$-1
	IN	A, (0)			; GET RD0
sioCmdPortRef6:	EQU	$-1
	RRA				; READY BIT TO CF
	JR	C,SIO_INTRCV1		; IF SET, DO SOME MORE
SIO_INTRCV4:
	OR	$FF			; NZ SET TO INDICATE INT HANDLED
	RET				; AND RETURN
;


_sioIn:
	LD	HL, SIO0A_CNT		; COUNT OF RECEIVE BUFFER
	LD	BC, 0

sioIn1:
	LD	A, (HL)			;
	OR	A			;
	JR	Z, sioIn4		;

	DI				; AVOID COLLISION WITH INT HANDLER
	LD	A, (HL)			; GET COUNT
	DEC	A			; DECREMENT COUNT
	LD	(HL),A			; SAVE UPDATED COUNT

	LD	HL, (SIO0A_TL)
	LD	C, (HL)			; C := CHAR TO BE RETURNED
	INC	L
	LD	(SIO0A_TL), HL
	EI				; INTERRUPTS OK AGAIN

	CP	BUFF_LOW_MARK		; BUFFER LOW THRESHOLD
	JR	Z, sioIn3		; IF NOT, BYPASS SETTING RTS

sioIn2:
	LD	L, C			; MOVE CHAR TO RETURN TO L
	LD	H, 0
	RET				; AND DONE

sioIn3:
	CALL	_sioRtsOn
	JR	sioIn2


sioIn4:
	DEC	BC
	LD	A, B
	OR	C
	JR	NZ, sioIn1

	LD	HL, $FF00
	RET

_sioIst:
	LD	A, (SIO0A_CNT)			; BUFFER UTILIZATION COUNT
	LD	L, A
	RET

_sioOut:
	CALL	SIO_OST			; READY FOR CHAR?
	JR	Z, _sioOut		; LOOP IF NOT
	LD	A,  L
	OUT	(0), A			; SEND CHAR FROM L
sioDataPortRef2: EQU	$-1
	RET

SIO_OST:
	XOR	A			; WR0
	DI
	OUT	(0), A			; DO IT
sioCmdPortRef7:	EQU	$-1
	IN	A, (0)			; GET STATUS
sioCmdPortRef8:	EQU	$-1
	EI
	AND	$04			; ISOLATE BIT 2 (TX EMPTY)
	ret	Z			; NOT READY, RETURN VIA IDLE PROCESSING
	XOR	A			; ZERO ACCUM
	INC	A			; ACCUM := 1 TO SIGNAL 1 BUFFER POSITION
	RET				; DONE

_sioRtsOff:
	DI
	LD	A, 5			; RTS IS IN WR5
	OUT	(0), A			; ADDRESS WR5
sioCmdPortRef9:	EQU	$-1
	LD	A, SIO_RTSOFF		; VALUE TO CLEAR RTS
	OUT	(0), A			; DO IT
sioCmdPortRefA:	EQU	$-1
	EI
	RET

_sioRtsOn:
	DI
	LD	A, 5			; RTS IS IN WR5
	OUT	(0), A			; ADDRESS WR5
sioCmdPortRefB:	EQU	$-1
	LD	A, SIO_RTSON		; VALUE TO SET RTS
	OUT	(0), A			; DO IT
sioCmdPortRefC:	EQU	$-1
	EI
	RET

_sioCfg:
	DB	0			; DEVICE NUMBER (SET DURING INIT)
	DB	0			; SIO TYPE (SET DURING INIT)
	DB	0			; CHIP 0 / CHANNEL B (LOW BIT IS CHANNEL)
sioCmdPort:
	DB	0			; CMD/STATUS PORT
sioDataPort:
	DB	0			; DATA PORT
	DW	0			; LINE CONFIGURATION
	DW	0			; POINTER TO RCV BUFFER STRUCT
	DW	0			; CLOCK FREQ AS
	DW	0			; ... DWORD VALUE
	DB	0			; CTC CHANNEL
	DB	0			; MODE

_sioCount:
SIO0A_CNT:	DB	0		; CHARACTERS IN RING BUFFER
sioHead:	DW	SIO0A_BUF	; BUFFER HEAD POINTER
sioTail:
SIO0A_TL:	DW	SIO0A_BUF	; BUFFER TAIL POINTER

_dataLoss:	DB	0

	SECTION IGNORE
