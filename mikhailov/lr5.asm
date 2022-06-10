AStack    SEGMENT  STACK
          DW 128 DUP(?)    
AStack    ENDS

DATA SEGMENT
    ALREADY_SET DB 'User interruption has already set',0DH,0AH,'$'
    WAS_SET DB 'User interruption was set',0DH,0AH,'$'
    RESTORE_SET DB 'Interruption restored',0DH,0AH,'$'
DATA ENDS
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

NEWINTERRUPTION PROC Far
	jmp stack_end
	PSP_START DW (?)
	KEEP_IP DW (?) 
	KEEP_CS DW (?) 
	
	SIGNATURE dw 0714h
	
	OLD_SS dw (?)
	OLD_SP dw (?)
	OLD_AX dw (?)
    REQ_KEY db 3eh
    NEW_STACK dw 64 dup()

    stack_end:
	
	mov OLD_SS, SS
	mov OLD_SP, SP
	mov OLD_AX, AX
	
	mov AX, CS
	mov SS, AX
	mov SP, offset stack_end
	
	push BX
	push CX
	push DX
	push DI
	push BP
	push DS
	
    in AL, 60h
    cmp AL, REQ_KEY
    je userset_int
    call dword ptr CS:KEEP_IP
    jmp pre_end
	
	userset_int:
	in AL, 61H 
	mov AH, AL 
	or AL, 80h 
	out 61H, AL
	xchg AH, AL
	out 61H, AL
	mov AL, 20H
	out 20H, AL
 
	read_buffer:
	mov AH, 05h 
	mov CL, 'F' 
	mov CH, 00h 
	int 16h 
	or AL, AL 
	jz pre_end
	mov AH, 0ch
	mov AL, 00h
	int 21h
	jmp read_buffer

    pre_end:
	pop DS
	pop BP
	pop DI
	pop DX
	pop CX
	pop BX
	
	mov SS, OLD_SS
	mov SP, OLD_SP
	mov AX, OLD_AX

	mov AL, 20h
	out 20h, AL
	IRET
	end_custom:
NEWINTERRUPTION ENDP

SET_INTERRUPTION PROC Near
    mov PSP_START, ES
    mov AH, 35h
    mov AL, 09h
    int 21h
    mov KEEP_IP, BX
    mov KEEP_CS, ES

    push DS
    mov DX, offset NEWINTERRUPTION
    mov AX, SEG NEWINTERRUPTION
    mov DS, AX
    mov AH, 25h
    mov AL, 09h
    int 21h
    pop DS

    mov DX, offset end_custom
    mov CL, 4
    shr DX, CL
    inc DX

    mov AX, CS
    sub AX, PSP_START
    add DX, AX

    mov AL, 0
    mov AH, 31h
    int 21h

    ret
SET_INTERRUPTION ENDP

GET_TAIL PROC Near
    push CX
    mov CX, 0
    mov CL, ES:[80h]
    cmp CX, 0
    je no_tail
    inc CX

	mov BL, ES:[80h+1]
	cmp BL, '/'

	mov BL, ES:[80h+2]
	cmp BL, 'u'
	
	mov BL, ES:[80h+2]
	cmp BL, 'n'
	mov BL, 1
	jmp end_get_tail

    no_tail:
	mov BL, 0
	
    end_get_tail:
	pop CX
	ret
GET_TAIL ENDP

CHECK_USERSET PROC
    push ES
    push BX

    mov AH, 35h
    mov AL, 09h
    int 21h

    mov AX, ES:[SIGNATURE]
    cmp AX, 0714h
    jne not_userset
    mov AL, 1
    jmp endcheck_userset

    not_userset:
    mov AL, 0

    endcheck_userset:
    pop BX
    pop ES
    ret
CHECK_USERSET ENDP

DISABLE_USERSET PROC
    mov AH, 35h
    mov AL, 09h
    int 21h

    CLI

    push DS

    mov DX, ES:[KEEP_IP]
    mov AX, ES:[KEEP_CS]
    mov DS, AX
    mov AL, 09h
    mov AH, 25h
    int 21h
    pop DS

    STI

    mov AX, ES:[PSP_START]
    mov ES, AX
    push ES

    mov AX, ES:[2Ch]
    mov ES, AX
    mov AH, 49h
    int 21h
    pop ES
    mov AH, 49h
    int 21h
    ret
DISABLE_USERSET ENDP

WRITESTRING PROC near
   mov ah, 09h
   int 21h
   ret
WRITESTRING ENDP

Main PROC FAR 
    mov AX, DATA
    mov DS, AX

    call CHECK_USERSET
    call GET_TAIL

    cmp AL, 1
    je is_user
    lea DX, WAS_SET
    call WRITESTRING
    call SET_INTERRUPTION
    jmp end_main

    is_user:
	lea DX, ALREADY_SET
	call WRITESTRING
	cmp BL, 1
	jne end_main
	
	lea DX, RESTORE_SET
	call WRITESTRING
	call DISABLE_USERSET

    end_main:
    xor AL, AL
    mov AH, 4Ch
    int 21h
Main ENDP
CODE ENDS

END Main 