TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

UNAVAILABLE_MEMORY_ADDRESS db 'Unavailable memory address:    ', 0DH, 0AH, '$'
ENV_ADDRESS db 'Segment environment address:    ', 0DH, 0AH, '$'
COMMAND_TAIL db 'Command tail:$'
COMMAND_TAIL_EMPTY db 'Command tail: empty', 0DH, 0AH, '$'
ENV_CONTENT db 'Segment environment content:', 0DH, 0AH, '$'
MODULE_PATH db 'Module path:$'

TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT:
    add AL, 30h
    ret
TETR_TO_HEX ENDP

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

BYTE_TO_DEC PROC near
    push CX
    push DX
    xor AH, AH
    xor DX, DX
    mov CX, 10
loop_bd:
    div CX
    or DL, 30h
    mov [SI], DL
    dec SI
    xor DX, DX
    cmp AX, 10
    jae loop_bd
    cmp AL, 00h
    je end_l
    or AL, 30h
    mov [SI], AL
end_l:
    pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP

PRINT_MESSAGE PROC near
	push AX
    mov AH, 9
    int 21h
	pop AX
    ret
PRINT_MESSAGE ENDP

PRINT_MESSAGE_BYTE  PROC  near
    push AX
    mov AH, 02h
    int 21h
    pop AX
    ret
PRINT_MESSAGE_BYTE  ENDP

PRINT_EOF PROC near
    push AX
    push DX
    mov DL, 0dh
    call PRINT_MESSAGE_BYTE
    mov DL, 0ah
    call PRINT_MESSAGE_BYTE
    pop DX
    pop AX
    ret
PRINT_EOF ENDP

UMA_TASK PROC near
    push AX
    push DI
    mov AX,DS:[02h]
	mov DI, offset UNAVAILABLE_MEMORY_ADDRESS
	add DI, 30
	call WRD_TO_HEX
	mov DX, offset UNAVAILABLE_MEMORY_ADDRESS
	call PRINT_MESSAGE
    pop DI
    pop AX
	ret
UMA_TASK ENDP

ENV_ADDRESS_TASK PROC near
    push AX
    push cx
    push DI
    mov AX,DS:[2ch]
	mov DI, offset ENV_ADDRESS
	add DI, 31
	call WRD_TO_HEX
	mov DX, offset ENV_ADDRESS
	call PRINT_MESSAGE
    pop DI
    pop CX
    pop AX
	ret
ENV_ADDRESS_TASK ENDP

COMMAND_TAIL_TASK PROC near
    push AX
    push CX
    push DX
    push DI
    xor CX, CX
    xor DI, DI
    mov CL, DS:[80h]
    cmp CL, 0
    je empty
    mov DX, offset COMMAND_TAIL
    call PRINT_MESSAGE
for_loop:
    mov DL, DS:[81h + DI]
    call PRINT_MESSAGE_BYTE
    inc DI
    loop for_loop
    call PRINT_EOF
    jmp restore
empty:
    mov DX, offset COMMAND_TAIL_EMPTY
    call PRINT_MESSAGE
restore:
    pop DI
    pop DX
    pop CX
    pop AX
	ret
COMMAND_TAIL_TASK ENDP

ENV_CONTENT_TASK PROC near
    push AX
    push DX
    push ES
    push DI
    mov DX, offset ENV_CONTENT
    call PRINT_MESSAGE
    xor DI, DI
    mov AX, ds:[2ch]
    mov ES, AX
for_loop_2:
    mov DL, ES:[DI]
    cmp DL, 0
    je end_2
    call PRINT_MESSAGE_BYTE
    inc DI
    jmp for_loop_2
end_2:
    call PRINT_EOF
    inc DI
    mov DL, ES:[DI]
    cmp DL, 0
    jne for_loop_2
    call MODULE_PATH_TASK
    pop DI
    pop ES
    pop DX
    pop AX
	ret
ENV_CONTENT_TASK ENDP

MODULE_PATH_TASK PROC near
    push AX
    push DX
    push ES
    push DI
    mov DX, offset MODULE_PATH
	call PRINT_MESSAGE
	add DI, 3
for_loop_3:
	mov DL, ES:[DI]
	cmp DL,0
	je restore_2
	call PRINT_MESSAGE_BYTE
	inc DI
	jmp for_loop_3
restore_2:
    call PRINT_EOF
    pop DI
    pop ES
    pop DX
    pop AX
	ret
MODULE_PATH_TASK ENDP

;----------------------------
BEGIN:
    call UMA_TASK
    call ENV_ADDRESS_TASK
    call COMMAND_TAIL_TASK
    call ENV_CONTENT_TASK
    
    xor AL, AL
    mov AH, 4ch
    int 21h

TESTPC  ENDS
        END START