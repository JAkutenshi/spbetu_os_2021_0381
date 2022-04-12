
AStack    SEGMENT  STACK
          DW 512 DUP(?)    
AStack    ENDS

DATA SEGMENT
    ALREADY_SET DB 'User interruption has already set',0DH,0AH,'$'
    WAS_SET DB 'User interruption was set',0DH,0AH,'$'
    RESTORE_SET DB 'Interruption restored',0DH,0AH,'$'
DATA ENDS
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack

outputBP proc
    push ax
    push bx
    push dx
    push CX
    mov ah,13h
    mov al,1
    mov bh,0
    int 10h
    pop CX
    pop dx
    pop bx
    pop ax
    ret
outputBP endp

setCurs proc
    push ax
    push bx
    push dx
    push CX
    mov ah,02h
    mov bh,0
    int 10h
    pop CX
    pop dx
    pop bx
    pop ax
    ret
setCurs endp

getCurs proc
 push ax
 push bx
 push CX
 mov ah,03h
 mov bh,0
 int 10h
 pop CX
 pop bx
 pop ax
 ret
getCurs endp

WRITESTRING PROC near
   push ax
   mov ah, 09h
   int 21h
   pop ax
   ret
WRITESTRING ENDP

UPDATE_COUNTER PROC
    push CX
    mov CX, 7
    check_number:
	mov AH, [DI]
	cmp AH, ' '
	je set_number
	cmp AH, '9'
	jl update_number
	mov AH, '0'
	mov [DI], AH
	dec DI
	dec CX
	cmp CX, 0
	jne check_number

    set_number:
	mov AH, '1'
	mov [DI], AH
	jmp end_check

    update_number:
	push DX
	pop DX
	inc AH
	mov [DI], AH

    end_check:
	pop CX
	ret
UPDATE_COUNTER ENDP

;обработчик
NEWINTERRUPTION PROC Far
	jmp stack_end
	PSP_START DW (?)
	KEEP_CS DW (?) 
	KEEP_IP DW (?) 
	
	SIGNATURE dw 0714h
	
	OLD_SS dw (?)
	OLD_SP dw (?)
	OLD_AX dw (?)
	
	COUNT_STRING db 'Count of interrupts:   0000'
	
	NEW_STACK dw 512 dup (?)
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
	push SI
	push BP
	push DS
	push ES
	
	mov AX, seg COUNT_STRING
	mov DS, AX
	lea DI, COUNT_STRING
	add DI, 26
	call UPDATE_COUNTER
	
	call getCurs
	push DX
	mov DX, 0
	call setCurs

	mov AX, SEG COUNT_STRING
	mov ES, AX
	mov BP, offset COUNT_STRING
	mov CX, 27
	call outputBP
	
	pop DX
	call setCurs

	pop ES
	pop DS
	pop BP
	pop SI
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
    mov AL, 1Ch
    int 21h
    mov KEEP_IP, BX
    mov KEEP_CS, ES

    push DS
    mov DX, offset NEWINTERRUPTION
    mov AX, SEG NEWINTERRUPTION
    mov DS, AX
    mov AH, 25h
    mov AL, 1Ch
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
    mov AL, 1Ch
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
    mov AL, 1Ch
    int 21h

    CLI

    push DS

    mov DX, ES:[KEEP_IP]
    mov AX, ES:[KEEP_CS]
    mov DS, AX
    mov AL, 1Ch
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

Main PROC FAR                            
    push DS
    sub AX, AX
    push AX
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