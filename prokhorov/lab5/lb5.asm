AStack    SEGMENT  STACK
          DW 128 DUP()    
AStack    ENDS

DATA      SEGMENT
ISINT DB 'Interruption is loaded',0Dh,0Ah,'$'
LOADINT DB 'Interruption was loaded',0Dh,0Ah,'$'
UNLOADINT DB 'Interruption was unloaded',0Dh,0Ah,'$'
DATA ENDS

CODE	SEGMENT
    	ASSUME SS:AStack, DS:DATA, CS:CODE

PUTS PROC NEAR
mov AH,09h
int 21h
ret
PUTS ENDP

NEWINT PROC FAR
jmp stack_end
PSP_START DW ?
KEEP_IP DW ?
KEEP_CS DW ?
	
NEW DW 0714h
	
OLD_SS DW ?
OLD_SP DW ?
OLD_AX DW ?
REQ_KEY DB 36h
STACK DW 64 DUP()
	
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
je start
call dword ptr CS:KEEP_IP
jmp pops
	
start:
	in AL, 61H 
	mov AH, AL 
	or AL, 80h 
	out 61H, AL
	xchg AH, AL
	out 61H, AL
	mov AL, 20H
	out 20H, AL
 
write:
	mov AH, 05h 
	mov CL, 'S' 
	mov CH, 00h 
	int 16h 
	or AL, AL 
	jz pops
	mov AH, 0ch
	mov AL, 00h
	int 21h
	jmp write
	
pops:	
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
end_int:
NEWINT ENDP

LOAD_NEWINT PROC NEAR
mov PSP_START, ES
mov AH, 35h
mov AL, 1Ch
int 21h
mov KEEP_IP, BX
mov KEEP_CS, ES

push DS
mov DX, offset NEWINT
mov AX, seg NEWINT
mov DS, AX
mov AH, 25h
mov AL, 1Ch
int 21h
pop DS

mov DX, offset end_int
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

UNLOAD_CHECK PROC NEAR
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

MAIN PROC FAR
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
MAIN      ENDP
CODE      ENDS

END MAIN
