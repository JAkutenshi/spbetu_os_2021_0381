CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack


NEW_INT PROC FAR
	jmp stack_end
	PSP_START dw ?
	KEEP_IP dw ?
	KEEP_CS dw ?
	
	CUSTOM dw 0714h
	
	OLD_SS dw ?
	OLD_SP dw ?
	OLD_AX dw ?
	REQ_KEY db 1dh
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
    je custom_int
    call dword ptr CS:KEEP_IP
    jmp pre_end
	
	custom_int:
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
	mov CL, 'I' 
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
	
	mov AX, OLD_AX
	mov SS, OLD_SS
	mov SP, OLD_SP
	
	mov AL, 20h
	out 20h, AL
	iret
	end_custom:
NEW_INT ENDP

SET_INT proc near
	mov PSP_START,es
	MOV AH, 35H 
	MOV AL, 09H 
	INT 21H
	MOV KEEP_IP, BX 
	MOV KEEP_CS, ES 

	PUSH DS
	MOV DX, OFFSET NEW_INT 
	MOV AX, SEG NEW_INT 
	MOV DS, AX 
	MOV AH, 25H 
	MOV AL, 09H
	INT 21H 
	POP DS
	
	mov DX, offset end_custom ; размер в байтах 
	mov CL, 4
	shr DX, CL
	inc DX
	mov AX, CS
    sub AX, PSP_START
    add DX, AX
	mov AL,0
	mov AH,31h
	
	int 21h
	
	ret
SET_INT endp

;проверка, нужно ли убрать обработчик
GET_COMMANDLINE_TAIL PROC Near
push CX
mov CX, 0
mov CL, ES:[80h]
cmp CX, 0
je noline
inc CX

mov SI, 0

get_letter1:
	inc SI
	cmp SI, CX
	je noline
	mov BL, ES:[80h+SI]
	cmp BL, '/'
	jne get_letter1

get_letter2:
	inc SI
	cmp SI, CX
	je noline
	mov BL, ES:[80h+SI]
	cmp BL, 'u'
	jne get_letter1
	
get_letter3:
	inc SI
	cmp SI, CX
	je noline
	mov BL, ES:[80h+SI]
	cmp BL, 'n'
	jne get_letter1
	mov BL, 1
	jmp end_get_tail

noline:
	mov BL, 0
	
end_get_tail:
	pop CX
	ret
GET_COMMANDLINE_TAIL ENDP


;проверка, установлен ли пользовательский обработчик
CHECK_CUSTOM PROC
push ES
push BX

mov AH, 35h
mov AL, 09h
int 21h

mov AX, ES:[CUSTOM]
cmp AX, 0714h
jne not_custom
mov AL, 1
jmp end_check_custom

not_custom:
mov AL, 0

end_check_custom:
pop BX
pop ES
ret
CHECK_CUSTOM ENDP


DISABLE_CUSTOM proc 
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
DISABLE_CUSTOM endp

;печать сообщения
WRITEMESSAGE PROC Near
mov AH,09h
int 21h
ret
WRITEMESSAGE ENDP


MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	
	call CHECK_CUSTOM
	call GET_COMMANDLINE_TAIL
	
	cmp AL, 1
	je is_custom
	lea DX, WAS_SET
	call WRITEMESSAGE
	call SET_INT
	jmp end_main
	
	is_custom:
	lea DX, IS_SET
	call WRITEMESSAGE
	cmp BL, 1
	jne end_main
	
	remove_custom:
		lea DX, NOT_SET
		call WRITEMESSAGE
		call DISABLE_CUSTOM
	
	end_main:
	xor AL, AL
	mov AH,4ch
	int 21h    
MAIN ENDP
CODE ENDS



AStack SEGMENT STACK
	dw 128 dup()
AStack ENDS

DATA SEGMENT
	IS_SET DB "Custom interruption is set",0DH,0AH,'$'
	WAS_SET DB "Custom interruption was set",0DH,0AH,'$'
	NOT_SET DB "Custom interruption is no longer set",0DH,0AH,'$'
DATA ENDS

END MAIN