.186
CODE SEGMENT
    ASSUME CS:CODE, SS:STACK

ROUT PROC FAR
    jmp start
    KEEP_CS DW 0
    KEEP_IP DW 0
    KEEP_SS DW 0
    KEEP_SP DW 0
    KEEP_AX DW 0
    OLD DD 0
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

    XOR AX, AX
    IN AL, 60h
    CMP AL, 10h ; key 'q/Q'
    JE do_req

    POPA
    MOV SP, KEEP_SP
    mov AX, KEEP_SS
    mov SS, AX
    mov AX, KEEP_CS
    MOV ES, AX
    mov AX, KEEP_AX
    JMP OLD
do_req:
    IN AL, 61h
    MOV ah, al
    OR AL, 10000000b
    OUT 61h, AL
    XCHG AH, AL
    OUT 61h, AL
    MOV AL, 20h
    OUT 20h, AL
write:
    MOV AH, 05h
    mov CL, 'Z'
    mov CH, 00h
    INT 16h
    OR AL, AL
    JZ no_overflow
    MOV AH, 0Ch
    MOV AL, 0h
    INT 21H
    JMP WRITE
no_overflow:
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
    cmp byte ptr ES:[BX+1], 0eh
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
    MOV AL, 09h
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
    MOV DX, ES:[BX + 5]
    MOV AX, ES:[BX + 3]
    MOV DS, AX
    MOV AH, 25H
    MOV AL, 09h
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
    MOV AL, 09h
    INT 21h
    MOV KEEP_IP, BX
    MOV KEEP_CS, ES
    MOV word ptr OLD, BX
    MOV word ptr OLD + 2, ES

    CLI
    PUSH DS
    MOV DX, OFFSET ROUT
    MOV AX, SEG ROUT
    MOV DS, AX
    MOV AH, 25h
    MOV AL, 09h
    INT 21h
    POP DS
    STI
     
    

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
