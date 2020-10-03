
	PUBLIC	_prepDma
	EXTERN	_sioIn, _checksum, _xprintf, _dataLossMessage

	SECTION CODE

diskBuffer1:	EQU 	$8200

_prepDma:
	LD	B, 0x80

	EXX
	LD	BC, diskBuffer1
	LD	HL, (_checksum)
	LD	D, 0
	EXX

prepDma1:
	PUSH	BC
	CALL	_sioIn
	POP	BC

	XOR	A
	OR	H
	JR	NZ, prepDmaDataLoss

	LD	A, L
	EXX
	LD	E, A
	ADD	HL, DE

	LD	(BC), A
	INC	BC
	EXX

	DJNZ	prepDma1

	EXX
	LD	(_checksum), HL

	RET

prepDmaDataLoss:
	LD	DE, _dataLossMessage
	PUSH	DE
	CALL	_xprintf
	POP	AF
  	RET

	SECTION IGNORE
