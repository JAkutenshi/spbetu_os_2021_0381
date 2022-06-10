AStack    SEGMENT  STACK
          DW 512 DUP(?)    
AStack    ENDS

DATA      SEGMENT
ISINT DB 'Interruption is loaded',0Dh,0Ah,'$'
LOADINT DB 'Interruption was loaded',0Dh,0Ah,'$'
UNLOADINT DB 'Interruption was unloaded',0Dh,0Ah,'$'
DATA ENDS

CODE	SEGMENT
    	ASSUME SS:AStack, DS:DATA, CS:CODE

outputBP proc
    push AX
    push BX
    push DX
    push CX
    mov AH,13h
    mov AL,1
    mov BH,0
    int 10h
    pop CX
    pop DX
    pop BX
    pop AX
    ret
outputBP endp

setCurs proc
    push AX
    push BX
    push DX
    push CX
    mov AH,02h
    mov BH,0
    int 10h
    pop CX
    pop DX
    pop BX
    pop AX
    ret
setCurs endp
 
getCurs proc
	push AX
 	push BX
 	push CX
 	mov AH,03h
 	mov BH,0
 	int 10h
 	pop CX
 	pop BX
 	pop AX
 	ret
getCurs endp

PUTS PROC Near
mov AH,09h
int 21h
ret
PUTS ENDP

COUNTER PROC
push CX
mov CX, 7

check_counter:
	mov AH, [DI]
	cmp AH, ' '
	je set
	cmp AH, '9'
	jl increment
	mov AH, '0'
	mov [DI], AH
	dec DI
	dec CX
	cmp CX, 0
	jne check_counter

set:
	mov AH, '1'
	mov [DI], AH
	jmp end_check

increment:
	push DX
	pop DX
	inc AH
	mov [DI], AH

end_check:
	pop CX
	ret
COUNTER ENDP

NEWINT PROC Far
jmp stack_end
PSP_START DW (?)
KEEP_CS DW (?)
KEEP_IP DW (?)
	
NEW DW 0714h
	
OLD_SS DW (?)
OLD_SP DW (?)
OLD_AX DW (?)
	
INT_COUNT DB 'Count of INT calls:           '
	
NEW_STACK DW 512 dup (?)
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
	
mov AX, seg INT_COUNT
mov DS, AX
lea DI, INT_COUNT
add DI, 25
call COUNTER
	
call getCurs
push DX
mov DX, 0
call setCurs

mov AX, seg INT_COUNT
mov ES, AX
mov BP, offset INT_COUNT
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
end_interruption:
NEWINT ENDP

LOAD_NEWINT PROC Near
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

mov DX, offset end_interruption
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
LOAD_NEWINT ENDP

CHECK_NEWINT PROC
push ES
push BX

mov AH, 35h
mov AL, 1Ch
int 21h

mov AX, ES:[NEW]
cmp AX, 0714h
jne not_int
mov AL, 1
jmp end_check_int

not_int:
mov AL, 0

end_check_int:
pop BX
pop ES
ret
CHECK_NEWINT ENDP

UNLOAD_CHECK PROC Near
push CX
mov CX, 0
mov CL, ES:[80h]
cmp CX, 0
je no_unload
inc CX

mov SI, 0

first_sym:
	inc SI
	cmp SI, CX
	je no_unload
	mov BL, ES:[80h+SI]
	cmp BL, '/'
	jne first_sym

second_sym:
	inc SI
	cmp SI, CX
	je no_unload
	mov BL, ES:[80h+SI]
	cmp BL, 'u'
	jne first_sym
	
third_sym:
	inc SI
	cmp SI, CX
	je no_unload
	mov BL, ES:[80h+SI]
	cmp BL, 'n'
	jne first_sym
	mov BL, 1
	jmp end_unload_check

no_unload:
	mov BL, 0
	
end_unload_check:
	pop CX
	ret
UNLOAD_CHECK ENDP

UNLOAD_NEWINT PROC
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
UNLOAD_NEWINT ENDP

Main Proc FAR                            
sub AX, AX
push AX
mov AX, DATA
mov DS, AX

call CHECK_NEWINT
call UNLOAD_CHECK

cmp AL, 1
je is_int
lea DX, LOADINT
call PUTS
call LOAD_NEWINT
jmp exit

is_int:
	lea DX, ISINT
	call PUTS
	cmp BL, 1
	jne exit
	
unload_int:
	lea DX, UNLOADINT
	call PUTS
	call UNLOAD_NEWINT

exit:
    xor AL, AL
    mov AH, 4Ch
    int 21h
Main      ENDP
CODE      ENDS

END Main