TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN

WORD_BUFFER db '    h',0DH,0AH,'$'
MEM_BEYOND db 'Segment of the first byte beyond the memory allocated to the program: $'
ENVIRONMENT db 'Environment segment: $'
CMD_TAIL db 'Command line tail:$'
ENV_VARS db 'Environment variables:',0DH,0AH,'$'
PROG_PATH db 'Program path: $'

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
    dec SI
    mov AL,BH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
    pop BX
    ret
WRD_TO_HEX ENDP

PRINT_MSG MACRO msg
    mov DX, offset msg
    mov AH, 09h
    int 21h
ENDM

NEWLINE MACRO
    mov DL, 0Dh
    int 21h
    mov DL, 0AH
    int 21h
ENDM

BEGIN:
    ;1
    PRINT_MSG MEM_BEYOND
    mov SI, offset WORD_BUFFER
    add SI, 3
    mov AX, ES:[2]
    call WRD_TO_HEX
    PRINT_MSG WORD_BUFFER
    ;2
    PRINT_MSG ENVIRONMENT
    add SI, 3
    mov AL, ES:[44]
    call WRD_TO_HEX
    PRINT_MSG WORD_BUFFER
    ;3
    PRINT_MSG CMD_TAIL
    mov AH, 02h
    mov BX, 81h
    xor CX, CX
    mov CL, ES:[80h]
    cmp CL, 0
    je ENV 
TAIL:
    mov DL, ES:[BX]
    int 21h
    inc BX
    loop TAIL
    NEWLINE
ENV:
    ;4
    PRINT_MSG ENV_VARS
    mov BX, ES:[2Ch]
    mov ES, BX
    mov AH, 02h
    mov BX, 0
TEXT:
    mov DL, ES:[BX]
STRING:
    int 21h
    inc BX
    cmp DL, 0
    jne TEXT
    NEWLINE
    mov DL, ES:[BX]
    cmp DL, 0
    jne STRING
    ;5
    push dx
    push ax
    PRINT_MSG PROG_PATH
    pop ax
    pop dx
    add BX, 3
PATH:
    mov DL, ES:[BX]
    int 21h
    inc BX
    cmp DL, 0
    jne PATH
    mov AH, 02h
    mov DL, 10
    int 21h
    mov DL, 13
    int 21h
    mov AH, 01h
    int 21h
    mov AH,4Ch
    int 21H
TESTPC ENDS
    END START