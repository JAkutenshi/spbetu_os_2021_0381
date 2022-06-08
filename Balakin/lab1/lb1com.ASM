TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN

PC db 'IBM PC type: PC',0DH,0AH,'$' ;FF
PCXT db 'IBM PC type: PC/XT',0DH,0AH,'$' ;FE, FB
PCJR db 'IBM PC type: PCjr',0DH,0AH,'$' ;FD
AT db 'IBM PC type: AT',0DH,0AH,'$' ;FC
PSTWOTHIRTY db 'IBM PC type: PS model 30',0DH,0AH,'$' ;FA
PCC db 'IBM PC type: PC Convertible',0DH,0AH,'$' ;F9
PSTWOEIGHTY db 'IBM PC type: PC model 80',0DH,0AH,'$' ;F8
VERSION db 'MS DOS version: 01.   ',0DH,0AH,'$'
OEM db 'OEM:   ',0DH,0AH,'$'
USER db 'User:       H',0DH,0AH,'$'
;ПРОЦЕДУРЫ
;-----------------------------------------------------
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

BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd: div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL
end_l: pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP

WRITE_MSG MACRO msg
    mov DX, offset msg
    mov AH, 09h
    int 21h
ENDM

MACRO_IF MACRO val, pctype
    cmp AL, val
    jne @f
    WRITE_MSG pctype
    jmp DOS_VESION
@@: 
ENDM

BEGIN:
    mov BX, 0F000h
    mov ES, BX
    mov AL, ES:[0FFFEh]
    cmp AL, 0F8h
    jb CUSTOM
    MACRO_IF 0FFh, PC
    MACRO_IF 0FEh, PCXT
    MACRO_IF 0FBh, PCXT
    MACRO_IF 0FDh, PCJR
    MACRO_IF 0FCh, AT
    MACRO_IF 0FAh, PSTWOTHIRTY
    MACRO_IF 0F8h, PSTWOEIGHTY
    MACRO_IF 0F9h, PCC
CUSTOM:
    call BYTE_TO_HEX
    mov BH, AH
    mov DL, AL
    mov AH, 06h
    int 21h
    mov DL, BH
    int 21h
DOS_VESION:
    mov AH, 30h
    int 21h
    mov SI, offset VERSION
    add SI, 17
    cmp AL, 00h
    je MODIFICATION
    mov DH, AH
    call BYTE_TO_DEC
    mov AL, DH
MODIFICATION:
    add SI, 3
    call BYTE_TO_DEC
    WRITE_MSG VERSION
OEM_NUM:
    mov AL, BH
    mov SI, offset OEM
    add SI, 6
    call BYTE_TO_DEC
    WRITE_MSG OEM
USER_NUM:
    mov SI, offset USER
    add SI, 11
    mov AX, CX
    call WRD_TO_HEX
    mov AL, BL
    call BYTE_TO_HEX
    sub SI, 2
    mov [SI], AX
    WRITE_MSG USER
    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
    END START