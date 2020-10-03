
	PUBLIC	_prepDma
	EXTERN	_sioIn, _checksum, _xprintf, _dataLossMessage

	SECTION CODE

diskBuffer1:	EQU 	$8200


_prepDma:
	ld	b, 0x80

	exx
	ld	bc, diskBuffer1
	ld	hl, (_checksum)
	ld	d, 0
	exx

l_prepDma_00103:
	push	bc
	call	_sioIn
	pop	bc

	XOR	A
	OR	H
	JR	NZ, prepDmaDataLoss

l_prepDma_00102:
	ld	a, l
	exx
	ld	e, a
	add	hl, de

	ld	(bc), a
	inc	bc
	exx

	djnz	l_prepDma_00103

	exx
	ld	(_checksum), hl

l_prepDma_00106:
	RET

prepDmaDataLoss:
	ld	de, _dataLossMessage
	push	de
	call	_xprintf
	pop	af
  	RET

	SECTION IGNORE
