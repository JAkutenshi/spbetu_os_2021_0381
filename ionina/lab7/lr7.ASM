AStack SEGMENT STACK
    DW 100 DUP(?)
AStack ENDS

DATA SEGMENT
PATH_ERROR db 'Can`t find path.', 0DH,0AH,'$'
FILE_ERROR db 'File is not found.', 0DH,0AH,'$'
DISK_ERROR db 'Disk error.', 0DH,0AH,'$'
NUM_ERROR db 'Incorrectly number.', 0DH,0AH,'$'
MCB_ERROR db 'MCB is destroyed.', 0DH,0AH,'$'
ADDRESS_ERROR db 'Invalid MCB address.', 0DH,0AH,'$'
NOT_ENOUGH_MEM_ERROR db 'Memory is not enough.', 0DH,0AH,'$'
ENVIRONMENT_ERROR db 'Wrong environment.', 0DH,0AH,'$'
ADD_MEMORY_ERROR db 'Error by adding memory.', 0DH,0AH,'$'
END_S db 0DH,0AH,'$'
PATH_ db 64 DUP(0)
OVERLAY_ADDRESS dd 0
DTA_BLOCK db 43 DUP(0) ; Буффер для DTA
OVERLAY_SEG dw 0
KEEP_PSP dw 0
PATH db 'Path: $'
    OVL1 db '1.ovl', 0
    OVL2 db '2.ovl', 0
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack

DTA_ PROC
    push DX
    mov DX, offset DTA_BLOCK
    mov AH, 1Ah
    int 21h
    pop DX
DTA_ ENDP

WRITE PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
WRITE ENDP

FREE_MEMORY PROC
    mov BX, offset ENDL
   	mov AX, ES
    sub BX, AX
    mov CL, 4
    shr BX, CL
    mov AH, 4Ah
    int 21h
    jnc ok
    cmp AX, 7
    mov DX, offset MCB_ERROR
    je err
    cmp AX, 8
    mov DX, offset ADDRESS_ERROR
    je err
    cmp AX, 9
    mov DX, offset ADDRESS_ERROR
err:
    call WRITE
    xor AL, AL
    mov AH, 4Ch
    int 21h
ok:
    ret
FREE_MEMORY ENDP

PATH_GET PROC
    push ES
    mov ES, ES:[2Ch]
    xor SI, SI
    mov DI, offset PATH_
first_move:
    add SI, 1
    cmp word ptr ES:[SI],0000h
    jne first_move
    add SI, 4
second_move:
    cmp byte ptr ES:[SI],00h
    je third_move
    mov DL, ES:[SI]
    mov [DI], DL
    add SI, 1
    add DI, 1
    jmp second_move
third_move:
    sub SI, 1
    sub DI, 1
    cmp byte ptr ES:[SI],'\'
    jne third_move
    add DI, 1
   	mov SI, BX
    push DS
    pop ES
fin_move:
    lodsb
    stosb
    cmp AL, 0
    jne fin_move
    mov byte ptr [DI],'$'
    mov DX, offset PATH
    call WRITE
    mov DX, offset PATH_
    call WRITE
    pop ES
    ret
PATH_GET ENDP

ALLOCATE_MEMORY_OVL PROC
	push DS
	push DX
    push CX
    xor CX, CX
	mov DX, offset PATH_
    mov AH, 4Eh
    int 21h
    jnc m2
    cmp AX, 3
	mov DX, offset PATH_ERROR
    je m1
	mov DX, offset FILE_ERROR
m1:
    call WRITE
    pop CX
    pop DX
   	pop DS
    xor AL, AL
    mov AH, 4Ch
    int 21h
m2:
    push ES
    push BX
    mov BX, offset DTA_BLOCK
    mov DX, [BX+1Ch]
    mov AX, [BX+1Ah]
    mov CL, 4h
    shr AX, CL
    mov CL, 12
    sal DX, CL
    add AX, DX
    add AX, 1
    mov BX, AX
    mov AH, 48h
    int 21h
    jc m3
    mov OVERLAY_SEG, AX
    pop BX
    pop ES
    pop CX
    pop DX
    pop DS
    ret
m3:
    mov DX, offset ADD_MEMORY_ERROR
    call WRITE
    mov AH, 4Ch
    int 21h
ALLOCATE_MEMORY_OVL ENDP

CHECK PROC
    cmp AX, 1
    mov DX, offset NUM_ERROR
    je print_error
    cmp AX, 2
    mov DX, offset FILE_ERROR
    je print_error
    cmp AX, 5
    mov DX, offset DISK_ERROR
    je print_error
    cmp AX, 8
    mov DX, offset NOT_ENOUGH_MEM_ERROR
    je print_error
    cmp AX, 10
    mov DX, offset ENVIRONMENT_ERROR
print_error:
    call WRITE
    ret
CHECK ENDP

OVL_LOAD PROC
    push DX
    push BX
   	push AX
    mov BX, SEG OVERLAY_SEG
    mov ES, BX
    mov BX, offset OVERLAY_SEG
    mov DX, offset PATH_
   	mov AX, 4B03h
    int 21h
    jnc ld
    call CHECK
    jmp endl_ovl
ld:
    mov AX, DATA
    mov DS, AX
    mov AX, OVERLAY_SEG
    mov word ptr OVERLAY_ADDRESS+2, AX
    call OVERLAY_ADDRESS
    mov AX, OVERLAY_SEG
    mov ES,AX
    mov AX, 4900h
    int 21h
    mov AX, DATA
    mov DS, AX
endl_ovl:
    mov ES, KEEP_PSP
    pop AX
    pop BX
    pop DX
    ret
OVL_LOAD ENDP

Main PROC FAR
    mov AX, DATA
    mov DS, AX
    mov KEEP_PSP, ES
    mov DX, offset END_S
    call WRITE
    call FREE_MEMORY
    call DTA_
    mov BX, offset OVL1
    call PATH_GET
    call ALLOCATE_MEMORY_OVL
    call OVL_LOAD
    mov BX, offset OVL2
    call PATH_GET
    call ALLOCATE_MEMORY_OVL
    call OVL_LOAD
    mov AH, 4Ch
    int 21h
Main ENDP
ENDL:
CODE ENDS
    END Main