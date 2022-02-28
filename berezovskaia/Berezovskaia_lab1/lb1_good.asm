STACK SEGMENT
    DW 8 dup(?)
STACK ENDS

DATA SEGMENT
PC_TYPE db 'IBM PC type: PC',0DH,0AH,'$' ;FF
PCXT_TYPE db 'IBM PC type: PC/XT',0DH,0AH,'$' ;FE, FB
PCJR_TYPE db 'IBM PC type: PCjr',0DH,0AH,'$' ;FD
AT_TYPE db 'IBM PC type: AT',0DH,0AH,'$' ;FC
PSTWOTHIRTY_TYPE db 'IBM PC type: PS model 30',0DH,0AH,'$' ;FA
PCC_TYPE db 'IBM PC type: PC Convertible',0DH,0AH,'$' ;F9
PSTWOEIGHTY_TYPE db 'IBM PC type: PC model 80',0DH,0AH,'$' ;F8
VERSION db 'MS DOS version: 01.   ',0DH,0AH,'$'
OEM_TYPE db 'OEM:   ',0DH,0AH,'$'
USER_TYPE db 'User:       H',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

WRITE_MSG MACRO msg
    mov DX, offset msg
    mov AH, 09h
    int 21h
ENDM

Main PROC FAR
    push ds
    xor ax, ax
    push ax
    mov ax, DATA
    mov ds, ax
    mov es, ax
    mov BX, 0F000h
    mov ES, BX
    mov AL, ES:[0FFFEh]
    cmp AL, 0F8h
    je PC
	cmp al, 0feh
	je pc_xt
	cmp al, 0fbh
	je pc_xt
	cmp al, 0fch
	je pc_at
	cmp al, 0fah
	je pc_ps2_m30
	cmp al, 0f8h
	je pc_ps2_m80
	cmp al, 0fdh
	je pc_jr
	cmp al, 0f9h
	je pc_conv
CUSTOM:
    call BYTE_TO_HEX
    mov BH, AH
    mov DL, AL
    mov AH, 06h
    int 21h
    mov DL, BH
    int 21h
PC:
    WRITE_MSG PC_TYPE
    jmp DOS_VESION
pc_xt:
    WRITE_MSG PCXT_TYPE
    jmp DOS_VESION
pc_at:
    WRITE_MSG AT_TYPE
    jmp DOS_VESION
pc_ps2_m30:
    WRITE_MSG PSTWOTHIRTY_TYPE
    jmp DOS_VESION
pc_ps2_m80:
    WRITE_MSG PSTWOEIGHTY_TYPE
    jmp DOS_VESION
pc_jr:
    WRITE_MSG PCJR_TYPE
    jmp DOS_VESION
pc_conv:
    WRITE_MSG PCC_TYPE
    jmp DOS_VESION   
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
    mov SI, offset OEM_TYPE
    add SI, 6
    call BYTE_TO_DEC
    WRITE_MSG OEM_TYPE
USER_NUM:
    mov SI, offset USER_TYPE
    add SI, 11
    mov AX, CX
    call WRD_TO_HEX
    mov AL, BL
    call BYTE_TO_HEX
    sub SI, 2
    mov [SI], AX
    WRITE_MSG USER_TYPE
    ret
Main ENDP

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

CODE ENDS
END Main