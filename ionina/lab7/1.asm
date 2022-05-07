OVL SEGMENT
    ASSUME CS:OVL, DS:NOTHING, SS:NOTHING, ES:NOTHING
Main PROC FAR
    push DS
    push AX
    push DI
    push DX
    push BX
   	mov DS, AX
    mov BX, offset SEGMENT_ADDRESS
    add BX, 21
    mov DI, BX
    mov AX, CS
    call WRD_TO_HEX
    mov DX, offset SEGMENT_ADDRESS
    call WRITE
    pop BX
    pop DX
    pop DI
    pop AX
    pop DS
    retf
Main ENDP

SEGMENT_ADDRESS  db ' Segment address:   h',0DH,0AH,'$'

TETR_TO_HEX PROC near
	and AL, 0Fh
	cmp AL, 09
	jbe cont
	add AL, 07
cont:	
    add AL, 30h
	ret
TETR_TO_HEX ENDP

WRITE PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
WRITE ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX
	pop CX		 
	ret 
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
	push BX
	mov BH, AH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	dec DI
	mov AL, BH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	pop BX
	ret
WRD_TO_HEX ENDP
OVL ENDS
    END Main 