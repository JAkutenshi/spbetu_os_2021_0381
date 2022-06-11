STACK SEGMENT
    DB 32  dup(?)
STACK ENDS

DATA SEGMENT
    MSG_ERROR1  DB 13, 10, 'Wrong func number.$'
    MSG_ERROR2  DB 13, 10, 'No such file.$'
    MSG_ERROR5  DB 13, 10, 'Disk error.$'
    MSG_ERROR8  DB 13, 10, 'Not enough memory.$'
    MSG_ERROR10 DB 13, 10, 'Wrong environment string.$'
    MSG_ERROR11 DB 13, 10, 'Wrong format.$'
    MSG_MEM7    DB 13, 10, 'MCB destroyed.$'
    MSG_MEM8    DB 13, 10, 'Not enough memory.$'
    MSG_MEM9    DB 13, 10, 'Wrong MCB address.$'
    RETURN_TER  DB 13, 10, 'Termitate/abort. $'
    RETURN_BRK  DB 13, 10, 'BREAK invoked.$'
    RETURN_HRD  DB 13, 10, 'Hard error.$'
    RETURN_RES  DB 13, 10, 'Terminate and stay resident.$'
    SAVE_SS     DW 0
    SAVE_SP     DW 0
    FN          DB 'F:\LB26.com', 0
    CMD         DB 0, 13
    ; === EPB ===
    ENV         DW 0
    CMD_OFF     DW offset CMD
    CMD_SEG     DW DATA
    FCB1        DD 0
    FCB2        DD 0
    LEN         DW $-ENV
    DSIZE=$-MSG_ERROR1
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, SS:STACK, DS:DATA
begin:

PRINT_MSG MACRO msg
    MOV DX, offset msg
    MOV AH, 09h
    INT 21h
ENDM

Main PROC FAR
    ; adjust memory usage
    MOV AH, 4Ah
    MOV BX, ((CSIZE/16)+1)+256/16+((DSIZE/16)+1)+256/16
    INT 21H
    JNB start 
    CMP AX, 7
    JNE @f
    PRINT_MSG MSG_MEM7
@@:
    CMP AX, 8
    JNE @f
    PRINT_MSG MSG_MEM8
@@:
    PRINT_MSG MSG_MEM9
    JMP exit
start:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX

    ; preparation for module
    LEA DX, FN 
    LEA BX, ENV
    MOV AX, SS
    MOV SAVE_SS, AX
    MOV SAVE_SP, SP
    ; call module
    MOV AX, 4B00h
    INT 21h
    ; jump if CF is set
    JB error
    MOV AX, DATA
    MOV DS, AX
    MOV AX, SAVE_SS
    MOV SS, AX
    MOV SP, SAVE_SP
    ; check return
    MOV AH, 4Dh
    INT 21h
    MOV BL, AL
    CMP AH, 0
    JNE @f
    PRINT_MSG RETURN_TER
@@:
    CMP AH, 1
    JNE @f
    PRINT_MSG RETURN_BRK
@@:
    CMP AH, 2
    JNE @f
    PRINT_MSG RETURN_HRD
@@:
    CMP AH, 3
    JNE @f
    PRINT_MSG RETURN_RES
@@:
    MOV AH, 02h
    MOV DL, 10
    INT 21h
    MOV DL, 13
    INT 21h
    MOV DL, BL 
    INT 21h 
    JMP exit
error:
    CMP AX, 1
    JNE @f
    PRINT_MSG MSG_ERROR1
@@:
    CMP AX, 2
    JNE @f
    PRINT_MSG MSG_ERROR2
@@:
    CMP AX, 5
    JNE @f
    PRINT_MSG MSG_ERROR5
@@:
    CMP AX, 8
    JNE @f
    PRINT_MSG MSG_ERROR8
@@:
    CMP AX, 10
    JNE @f
    PRINT_MSG MSG_ERROR10
@@:
CMP AX, 11
    JNE exit
    PRINT_MSG MSG_ERROR11
exit:
    XOR AL, AL
    MOV AH, 4Ch
    INT 21h
Main ENDP
CSIZE=$-begin
CODE ENDS

END Main