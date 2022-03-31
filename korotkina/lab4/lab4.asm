CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack

;печать сообщения
WRITEMESSAGE PROC Near
mov AH,09h
int 21h
ret
WRITEMESSAGE ENDP

;функция вывода строки по адресу ES:BP на экран
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

;установить курсор
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
 
;получить положение курсора
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

;обновление счетчика
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
NEWINT PROC Far
	jmp stack_end
	PSP_START DW (?)
	KEEP_CS DW (?) ; для хранения сегмента
	KEEP_IP DW (?) ; и смещения прерывания
	
	CUSTOM dw 0714h
	
	OLD_SS dw (?)
	OLD_SP dw (?)
	OLD_AX dw (?)
	
	INT_NUM_STRING db 'Int was called       times'
	
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
	
	mov AX, seg INT_NUM_STRING
	mov DS, AX
	lea DI, INT_NUM_STRING
	add DI, 20
	call UPDATE_COUNTER
	
	call getCurs
	push DX
	mov DX, 0
	call setCurs

	mov AX, SEG INT_NUM_STRING
	mov ES, AX
	mov BP, offset INT_NUM_STRING
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
NEWINT ENDP

;установить обработчик
SET_INTERRUPTION PROC Near
mov PSP_START, ES
mov AH, 35h
mov AL, 1Ch
int 21h
mov KEEP_IP, BX
mov KEEP_CS, ES

push DS
mov DX, offset NEWINT
mov AX, SEG NEWINT
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

;проверка, нужно ли выводить блоки памяти
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
mov AL, 1Ch
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

;убрать пользовательский разработчик
DISABLE_CUSTOM PROC
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
DISABLE_CUSTOM ENDP

Main 	Proc FAR                            
sub AX, AX
push AX
mov AX, DATA
mov DS, AX

call CHECK_CUSTOM
call GET_COMMANDLINE_TAIL

cmp AL, 1
je is_custom
lea DX, WAS_SET
call WRITEMESSAGE
call SET_INTERRUPTION
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
mov AH, 4Ch
int 21h
Main      ENDP
CODE      ENDS

AStack    SEGMENT  STACK
          DW 512 DUP(?)    
AStack    ENDS

DATA      SEGMENT
IS_SET DB 'Custom interruption is set',0DH,0AH,'$'
WAS_SET DB 'Custom interruption was set',0DH,0AH,'$'
NOT_SET DB 'Custom interruption is no longer set',0DH,0AH,'$'
DATA ENDS
          END Main