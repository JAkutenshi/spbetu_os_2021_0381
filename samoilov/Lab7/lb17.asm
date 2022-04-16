.model small
.code

    ORG 100H
MAIN PROC

    JMP BEGIN

; DATA
    WORD_BUFFER db '    h',0DH,0AH,'$'
    MEM_SEG db 'Overlay No.1 location: $'

begin:
    PUSH DS
    PUSH CS
    POP DS
    lea DX, [MEM_SEG-100h]
    mov AH, 09h
    int 21h
    lea SI, [WORD_BUFFER+3-100h]
    mov AX, DS
    call WRD_TO_HEX
    lea DX, [WORD_BUFFER-100h]
    mov AH, 09h
    int 21h
    POP DS
    RETF
MAIN ENDP

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

    END MAIN