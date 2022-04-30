

AStack    SEGMENT  STACK
          DW 512 DUP(?)    
AStack    ENDS

DATA      SEGMENT
PARAMETR_BLOCK db 14 dup()
NEWLINE db 0DH,0AH,'$'
ERROR7 DB "Can't spread memory: block destroyed",0DH,0AH,'$'
ERROR8 DB "Can't spread memory: not enough memory",0DH,0AH,'$'
ERROR9 DB "Can't spread memory: wrong address",0DH,0AH,'$'
PATH_TO_FILE db 50 dup(0)
MODULE_NAME db "LAB2.com",0
KEEP_SS dw ?
KEEP_SP dw ?

CALLERROR1 db "Wrong function number",0DH,0AH,'$'
CALLERROR2 db "File not found",0DH,0AH,'$'
CALLERROR5 db "Disk error",0DH,0AH,'$'
CALLERROR8 db "Not enought memory",0DH,0AH,'$'
CALLERROR10 db "Wrong env line",0DH,0AH,'$'
CALLERROR11 db "Wrong format",0DH,0AH,'$'

ENDCODE0 db "Ok",0DH,0AH,'$'
ENDCODE1 db 0DH,0AH,"Ctrl-Break",0DH,0AH,'$'
ENDCODE2 db 0DH,0AH,"Error occured",0DH,0AH,'$'
ENDCODE3 db 0DH,0AH,"int31h called",0DH,0AH,'$'
ENDCODE db 0DH,0AH,"Ended with code: 000",0DH,0AH,'$'
DATA ENDS

CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack
		  
;печать сообщения
WRITEMESSAGE PROC Near
mov AH,09h
int 21h
ret
WRITEMESSAGE ENDP		  

BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
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
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP

SPREAD_MEMORY PROC near
push AX
push BX
push DX

mov BX, offset program_end
mov AX, ES
sub BX, AX
mov CL, 4
shr BX, CL
inc BX
mov AH, 4Ah
int 21h
jnc succes

cmp AX, 7
jne error_8
lea DX, ERROR7
jmp show_warning

error_8:
cmp AX, 8
jne error_9
lea DX, ERROR8
jmp show_warning

error_9:
cmp AX, 9
jne succes
lea DX, ERROR9

show_warning:
call WRITEMESSAGE

succes:
pop DX
pop BX
pop AX
ret
SPREAD_MEMORY ENDP

GET_PARAMS PROC Near
push ES
push AX
push SI

sub SI, SI
mov ES, ES:[2Ch]

find_loop:
	mov AL, ES:[SI]
	inc SI
	cmp AL, 0
	jne find_loop
	mov AL, ES:[SI]
	cmp AL, 0
	jne find_loop
	
add SI, 3
push SI

find_slash:
	cmp byte ptr ES:[SI], '\'
	jne next_char
	mov AX, SI
	
	next_char:
		inc SI
		cmp byte ptr ES:[SI], 0
		jne find_slash
		inc AX
		pop SI
		mov DI, 0

save_path:
	mov BL, ES:[SI]
	mov PATH_TO_FILE[DI], BL
	inc SI
	inc DI
	cmp SI, AX
	jne save_path

mov SI, 0

add_filename:
	mov BL, MODULE_NAME[SI]
	mov PATH_TO_FILE[DI], BL
	inc SI
	inc DI
	cmp BL, 0
	jne add_filename

pop SI
pop AX
pop ES
ret
GET_PARAMS ENDP

CALL_MODULE PROC Near
push DS
push ES

mov word ptr PARAMETR_BLOCK[2], ES
mov word ptr PARAMETR_BLOCK[4], 80h

mov AX, DS
mov ES, AX
mov DX, offset PATH_TO_FILE
mov BX, offset PARAMETR_BLOCK
mov KEEP_SS, SS
mov KEEP_SP, SP
mov AX, 4B00h
int 21h
mov SS, KEEP_SS
mov SP, KEEP_SP

jnc succes_end

mov BL, 1
cmp AX, 1
jne call_error_2
lea DX, CALLERROR1
jmp write_error
call_error_2:
	cmp AX, 2
	jne call_error_5
	lea DX, CALLERROR2
	jmp write_error
call_error_5:
	cmp AX, 5
	jne call_error_8
	lea DX, CALLERROR5
	jmp write_error
call_error_8:
	cmp AX, 8
	jne call_error_10
	lea DX, CALLERROR8
	jmp write_error
call_error_10:
	cmp AX, 10
	jne call_error_11
	lea DX, CALLERROR10
	jmp write_error
call_error_11:
	lea DX, CALLERROR11
write_error:
	call WRITEMESSAGE
	jmp end_proc
	
succes_end:
	mov BL, 0

end_proc:
pop ES
pop DS
ret
CALL_MODULE ENDP

Main 	Proc FAR                            
   push ds
   sub ax, ax
   push ax
   mov ax, DATA
   mov ds, ax

	call GET_PARAMS
	call SPREAD_MEMORY
	call CALL_MODULE
	cmp BL, 0
jne end_main_proc

mov AH, 4DH
int 21h

cmp AH, 0
je good_end


ctr_end:
cmp AH, 1
jne err_end
lea DX, ENDCODE1
jmp write_end_mess

err_end:
cmp AH, 2
jne res_end
lea DX, ENDCODE2
jmp write_end_mess

res_end:
lea DX, ENDCODE3

good_end:
lea SI, ENDCODE
add SI, 21
call BYTE_TO_DEC
lea DX, ENDCODE
call WRITEMESSAGE
lea DX, ENDCODE0
jmp write_end_mess

write_end_mess:
call WRITEMESSAGE

end_main_proc:
	mov AH, 4Ch
	int 21h
	RET
	program_end:
Main      ENDP
CODE      ENDS
          END Main