.186
CODE SEGMENT
    ASSUME CS:CODE, SS:STACK

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

ROUT PROC FAR
    jmp start
    COUNTER DW 0
    KEEP_CS DW 0
    KEEP_IP DW 0
    KEEP_SS DW 0
    KEEP_SP DW 0
    KEEP_AX DW 0
    WORD_BUFFER db '    $'
    ROUT_STACK DW 128 dup(0)
start:
    MOV KEEP_SP, SP
    MOV KEEP_AX, AX
    MOV AX, SS
    MOV KEEP_SS, AX
    MOV SP, offset start
    DEC SP
    MOV AX, seg ROUT_STACK
    MOV SS, AX
    MOV AX, KEEP_AX
    PUSHA          
    MOV BX, SEG COUNTER
    MOV ES, BX
    MOV BX, OFFSET COUNTER
    MOV CX, ES:[BX]
    cmp CX, 500
    jne increase
    xor CX, CX
increase:
    INC CX
    MOV ES:[BX], CX
    MOV CX, 12
    mov AL, СL
    mov SI, offset WORD_BUFFER
    add SI, 3
    call BYTE_TO_DEC
    mov AL, СH
    call BYTE_TO_DEC
    mov ah, 13h ; функция
    mov BL, 15d
    mov BP, offset WORD_BUFFER
    mov al, 0 ; sub function code
    ; 1 = use attribute in BL; leave cursor at end of string
    mov bh, 0 ; видео страница
    mov cx, 4
    mov dh, 1 ; DH,DL = строка, колонка (считая от 0)
    mov dl, 60d
    int 10h

    POPA 
    MOV SP, KEEP_SP
    mov AX, KEEP_SS
    mov SS, AX
    mov AX, KEEP_AX
    MOV  AL, 20h
    OUT  20h, AL
    IRET
rout_end:
ROUT ENDP

IS_LOADED PROC NEAR
    push ES
    PUSH BX
    PUSH AX
    MOV AX, KEEP_CS
    MOV ES, AX
    XOR CX, CX
    MOV BX, KEEP_IP
    cmp byte ptr ES:[BX], 0e9h
    jne notset
    cmp byte ptr ES:[BX+1], 11h
    jne notset
    cmp byte ptr ES:[BX+2], 01h
    jne notset
    INC CX
notset:
    POP AX
    POP BX
    POP ES
    ret
IS_LOADED ENDP

UN_OPTION PROC NEAR
    PUSH AX
    XOR CX, CX
    MOV AL, ES:[80h]
    cmp AL, 4
    jne noflag
    mov AL, ES:[82h]
    cmp AL, '/'
    jne noflag
    mov AL, ES:[83h]
    cmp AL, 'u'
    jne noflag
    mov AL, ES:[84h]
    cmp AL, 'n'
    jne noflag
    INC CX
noflag:
    POP AX
    ret
UN_OPTION ENDP

Main PROC FAR
    MOV AX, DATA
    MOV DS, AX

    PUSH ES
    MOV AH, 35h
    MOV AL, 1ch
    INT 21h
    MOV KEEP_IP, BX
    MOV KEEP_CS, ES
    POP ES
    call IS_LOADED
    cmp CX, 0
    je not_loaded
;loaded
    call UN_OPTION
    cmp CX, 1
    je unload
    mov DX, offset INT_SET
    mov AH, 09h
    int 21h
    jmp exit
unload:
    CLI
    PUSH ES
    PUSH DS
    mov AX, KEEP_CS
    mov ES, AX
    mov BX, KEEP_IP
    MOV DX, ES:[BX + 7]
    MOV AX, ES:[BX + 5]
    MOV DS, AX
    MOV AH, 25H
    MOV AL, 23h
    INT 21H
    POP DS
    mov ah, 49h
    int 21h
    POP ES
    STI
    jmp exit

not_loaded:
    call UN_OPTION
    cmp CX, 1
    je exit
;load
    MOV AH, 35h
    MOV AL, 1ch
    INT 21h
    MOV KEEP_IP, BX
    MOV KEEP_CS, ES

    CLI
    PUSH DS
    MOV DX, OFFSET ROUT
    MOV AX, SEG ROUT
    MOV DS, AX
    MOV AH, 25h
    MOV AL, 1ch
    INT 21h
    POP DS
    STI

    int 1ch
    int 1ch
    int 1ch

    LEA DX, rout_end
    SHR DX, 4
    INC DX
    MOV AH, 31h
    INT 21h 

exit:
    MOV AH, 4Ch
    INT 21h
Main ENDP
CODE ENDS

DATA SEGMENT
    INT_SET DB 'Interruption is set, leaving.$'
DATA ENDS

STACK SEGMENT
    DB 32  dup(?)
STACK ENDS

END Main
