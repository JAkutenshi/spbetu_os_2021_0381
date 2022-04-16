.186
STACK SEGMENT
    DB 32  dup(?)
STACK ENDS

DATA SEGMENT
    MEM_ERR  DB  13, 10, 'Memory adjustment error.$'
    FND_ERR  DB  13, 10, 'Can not find the file.$'
    ALL_ERR  DB  13, 10, 'Allocation failed.$'
    FRE_ERR  DB  13, 10, 'Free failed.$'
    OVL_ERR  DB  13, 10, 'Overlay call error.$'
    OVL_SUC  DB  13, 10, 'Ov executed.$'
    OVRLAY1  DB  'F:\LB17.ovl', 0
    OVRLAY2  DB  'F:\LB27.ovl', 0
    DTA      DB  44 dup (0)
    SAVE_SS  DW  0
    SAVE_SP  DW  0
    ENTRY_P  DD  0
    
    ; === EPB ===
    LOAD_SG  DW  0
    RELOC_F  DW  0

    DSIZE=$-MEM_ERR
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, SS:STACK, DS:DATA
begin:

PRINT_MSG MACRO msg
    MOV DX, offset msg
    MOV AH, 09h
    INT 21h
ENDM

OV_EXEC MACRO ovl
; Find overlay
    MOV DX, offset ovl
    XOR CX, CX
    MOV AX, 4E00h
    INT 21h
    JNB @f
        JMP nfnd
@@:

; Get size from DTA
    MOV BX, offset DTA
    MOV AX, [BX + 1Ah]
    SHR AX, 4
    INC AX
    SHL AX, 4

; Allocate memory
    MOV BX, AX
    MOV AH, 48h
    INT 21H
    JNB @f
        JMP alloc_error
@@:
    MOV [LOAD_SG], AX
    MOV [RELOC_F], AX
    MOV word ptr [ENTRY_P + 2], AX

; Call overlay
    MOV AX, 4B03h
    MOV BX, offset LOAD_SG
    INT 21h

; Recover registers DS, ES, SS, SP
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX
    MOV SS, SAVE_SS
    MOV SP, SAVE_SP

; Check if EXEC was successful
    JNB @f
        JMP ov_error
@@:

; Call Overlay
    PUSH DS
    call dword ptr[ENTRY_P]
    POP DS

; Free memory
    MOV AX, LOAD_SG
    MOV ES, AX
    MOV AH, 49h
    INT 21h
    JNB @f
        JMP free_error
@@:
    MOV AX, DATA
    MOV ES, AX
ENDM

Main PROC FAR
; Adjust memory usage
    MOV AH, 4Ah
    MOV BX, ((CSIZE/16)+1)+256/16+((DSIZE/16)+1)+256/16
    INT 21H
    JC @f
    JMP ResizeMemOk
    @@:
        PRINT_MSG MEM_ERR
ResizeMemOk:

; Save and set registers 
    MOV SAVE_SS, SS
    MOV SAVE_SP, SP
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX

; Set DTA
    MOV AH, 1Ah
    MOV DX, offset DTA
    INT 21h

; Execute macros
    OV_EXEC OVRLAY1
    OV_EXEC OVRLAY2
    JMP EXIT

; Errors handling
    JMP exit
ov_error:
    PRINT_MSG OVL_ERR
    JMP EXIT
alloc_error:
    PRINT_MSG ALL_ERR
    JMP EXIT
free_error:
    PRINT_MSG FRE_ERR
    JMP EXIT
nfnd:
    PRINT_MSG FND_ERR

; Exit
exit:
    XOR AL, AL
    MOV AH, 4Ch
    INT 21h
Main ENDP
CSIZE=$-begin
CODE ENDS

END Main
