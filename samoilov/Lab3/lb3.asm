.186
TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN

WORD_BUFFER db '    $'
FREE db 0DH,0AH,0DH,0AH,'Free memory: $'
EXTENDED db 0DH,0AH,'Extended memory: $'

MCB db 0DH,0AH,'Memory control block.',0DH,0AH,'$'
OWNER db '  Owner: $'
PARAGRAPHS db 0DH,0AH,'  Size (paragraphs): $'
SD db 0DH,0AH,'  SC/SD: $'

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

HEX MACRO
    mov DL, 'h'
    mov AH, 02h
    int 21h
ENDM

WORD_TO_BUFFER MACRO
    mov SI, offset WORD_BUFFER
    add SI, 3
    call WRD_TO_HEX
ENDM

BEGIN:
    ;free memory
    ;mov bx,4096
    ;mov AH,4ah
    ;int 21H
    
    ; Allocate memory
    ;mov bx,4096
    ;mov AH,48h
    ;int 21H
    
    ; в зависимости от шага лабораторной работы,
    ; освобождение и аллокация переставляются и убираются
    ; из комментариев.

    xor CX, CX ; free memory counter

    mov AH, 52h
    int 21h
    mov AX, ES:[BX-2]
    mov ES, AX
    push CX
pages:
    PRINT_MSG MCB
    
    PRINT_MSG OWNER
    mov AX, ES:[1] ; free or not
    WORD_TO_BUFFER
    PRINT_MSG WORD_BUFFER
    HEX
    
    push AX
    PRINT_MSG PARAGRAPHS
    mov BX, ES:[3] ; size in paragraphs (16 bytes)
    mov AL, BL
    mov SI, offset WORD_BUFFER
    add SI, 3
    call BYTE_TO_DEC
    mov AL, BH
    call BYTE_TO_DEC
    PRINT_MSG WORD_BUFFER
    
    pop AX
    cmp AX, 0h
    jne taken
    pop CX
    add CX, BX ; adjust free mem counter
    push CX
taken:
    push BX
    PRINT_MSG SD
    mov BX, -1
    mov AH, 02h
text:
    inc BX
    mov DL, ES:[8 + BX]
    int 21h
    cmp BX, 7
    jne text 
    pop BX
    mov AL, ES:[0] ; last or not
    mov DX, ES
    inc DX
    add DX, BX
    mov ES, DX
    cmp AL, 4Dh
    je pages

    ; Amount of free mem
    pop CX
    mov AX, CX
    WORD_TO_BUFFER
    PRINT_MSG FREE
    PRINT_MSG WORD_BUFFER
    HEX
    
    ; extended mem
    mov AL,30h ; запись адреса ячейки CMOS
    out 70h,AL
    in AL,71h  ; чтение младшего байта
    mov BL,AL  ; размера расширенной памяти
    mov AL,31h ; запись адреса ячейки CMOS
    out 70h,AL
    in AL,71h  ; чтение старшего байта
    mov BH, AL ; размера расширенной памяти
    mov AX, BX
    WORD_TO_BUFFER
    PRINT_MSG EXTENDED
    PRINT_MSG WORD_BUFFER
    HEX

    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
    END START