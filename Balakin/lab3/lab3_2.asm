TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN

AV_MEM_STRING db 'Available memory: ',0DH,0AH,'$'
EXTENDED_MEM_STRING db 'Extended memory: ',0DH,0AH,'$'
MCB_TYPE_STRING db 'MCB type is:      ', '$'
PSP_TYPE_STRING db 'PSP adress is:      ', '$'
SIZE_STRING db 'Size is:    ', '$'
SC_SD_STRING db 'SC/SD: ', '$'
NEWLINE db 0DH, 0AH, '$'
TAB db '  ', '$'
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:   add AL,30h
        ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа AX
            push CX
            mov AH,AL
            call TETR_TO_HEX
            xchg AL,AH
            mov CL,4
            shr AL,CL
            call TETR_TO_HEX ; В AL Старшая цифра 
            pop CX           ; В AH младшая цифра
            ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа   
        push BX
        mov BH,AH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        dec DI
        mov AL,BH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        pop BX
        ret
WRD_TO_HEX ENDP
;--------------------------------------------------
WRITE_STRING PROC near; Вывод строки текста
        mov AH,09h
        int 21h
        ret
WRITE_STRING ENDP

PARAGRAPH_TO_BYTE PROC
	mov bx, 0ah
	xor cx, cx

loop_pb:
	div bx
	push dx
	inc cx
	sub dx, dx
	cmp ax, 0h
	jne loop_pb
write_symbol:
	pop dx			
	add dl,30h		
	mov ah,02h
	int 21h
			
	loop write_symbol

	ret
PARAGRAPH_TO_BYTE ENDP

AVAILABLE_MEM PROC near
    MOV dx, offset AV_MEM_STRING
    CALL WRITE_STRING

    MOV AH,4AH 
    MOV BX,0FFFFH ; заведомо большой блока памяти
    INT 21H

    MOV AX, BX
    MOV BX, 16
    MUL BX
    CALL PARAGRAPH_TO_BYTE
    MOV DX, offset NEWLINE
    CALL WRITE_STRING

    ret

AVAILABLE_MEM ENDP

EXTENDED_MEM PROC near
    MOV dx, offset EXTENDED_MEM_STRING
    CALL WRITE_STRING

    mov AL, 30h
    out 70h, AL
    in AL, 71h
    MOV BL,AL
   	mov AL, 31h
    out 70h, AL
    in AL, 71h
    MOV BH, AL
    MOV AX, BX

    MOV BX, 16
    MUL BX
    CALL PARAGRAPH_TO_BYTE
    MOV DX, offset NEWLINE
    CALL WRITE_STRING
    ret

EXTENDED_MEM ENDP

MCB PROC near
    MOV ah, 52h
    int 21H
    mov AX, ES:[BX-2]
    MOV ES, AX

MCB_loop:
    MOV AX, ES
    MOV DI, offset MCB_TYPE_STRING
    add DI, 17
    CALL WRD_TO_HEX
    MOV DX, offset MCB_TYPE_STRING
    CALL WRITE_STRING
    MOV DX, offset TAB
    CALL WRITE_STRING
    
    MOV AX, ES:[1]
    MOV DI, offset PSP_TYPE_STRING
    add DI, 19
    CALL WRD_TO_HEX
    MOV DX, offset PSP_TYPE_STRING
    CALL WRITE_STRING
    MOV DX, offset TAB
    CALL WRITE_STRING

    MOV DX, offset SIZE_STRING
    CALL WRITE_STRING
    MOV AX, ES:[3]
    MOV DI, offset SIZE_STRING
    ADD DI, 10
    MOV BX, 16
    MUL BX
    CALL PARAGRAPH_TO_BYTE
    MOV DX, offset TAB
    CALL WRITE_STRING

    MOV DX, offset TAB
    CALL WRITE_STRING

    MOV DX, offset SC_SD_STRING
    call WRITE_STRING
    
    MOV BX, 8
    MOV CX, 08h

SC_SD_loop:
    MOV DL, ES:[BX]
    MOV AH, 02H
    INT 21H
    INC BX
    LOOP SC_SD_LOOP

    MOV DX, offset NEWLINE
    CALL WRITE_STRING
    
    MOV BX, ES:[3H]
    MOV AL, ES:[0H]
    CMP AL, 5AH
    JE MCB_END

    MOV AX, ES
    INC AX
    ADD AX, BX
    MOV ES, AX
    JMP MCB_loop

MCB_END:
	ret

MCB ENDP

CLEAR_MEMORY PROC near
    MOV     AX, CS
    MOV     ES, AX
    MOV     BX, offset TESTPC_END
    MOV     AX, ES
    MOV     BX, AX
    MOV     AH, 4AH
    INT     21H
    RET
CLEAR_MEMORY ENDP




BEGIN:
        CALL AVAILABLE_MEM
        CALL EXTENDED_MEM
        CALL CLEAR_MEMORY
        CALL MCB
;. . . . . . . . . . . .
; Выход в DOS
        xor AL,AL
        mov AH,4Ch
        int 21H

TESTPC_END:
TESTPC  ENDS
        END START ;