AStack SEGMENT STACK
	dw 128 dup()
AStack ENDS

DATA SEGMENT
	PARAMETER_BLOCK db 14 dup(0)
    ERR7 db 'The memory control block is destroyed',0Dh,0Ah,'$'
    ERR8 db 'Not enough memory to perform the function',0Dh,0Ah,'$'
    ERR9 db 'Invalid memory block address',0Dh,0Ah,'$'
	FILE db 'File $'
    AERR1 db 'Function number is not correct',0Dh,0Ah,'$'
    AERR5 db 'Disk error',0Dh,0Ah,'$'
    AERR8 db 'Not enough memory',0Dh,0Ah,'$'
    AERR10 db 'Wrong environment string',0Dh,0Ah,'$'
    AERR11 db 'Incorrect format',0Dh,0Ah,'$'
	EXITCODE0 db 0Dh,0Ah,'Terminated with code 000$'
    EXITCODE1 db 0DH,0AH,"Terminated with CTRL+C, code 000$"
    EXITCODE2 db 'Device error termination',0Dh,0Ah,'$' 
    EXITCODE3 db 'Termination by function 31h',0Dh,0Ah,'$' 
	NOT_FOUND db ' not found $'
	FILENAME db 'LB2.com$',0
	PATH db 50 dup(0)
	NEWLINE db 0Dh,0Ah,'$'
	TMP_SS dw ?
	TMP_SP dw ?
DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

BYTE_TO_DEC PROC near
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

PUTS PROC NEAR
mov AH,09h
int 21h
ret
PUTS ENDP

MAIN PROC FAR
mov ax, DATA
mov ds, ax
push es
	
mov si,0
mov es, es:[2Ch]

env_loop:
mov al,es:[si]
inc si
cmp al,0
jne env_loop
mov al,es:[si]
cmp al,0
jne env_loop	
	
add si,3
push si
slash_search:
cmp byte ptr es:[si],'\'
jne slash_found
mov ax,si

slash_found:
inc si
cmp byte ptr es:[si],0
jne slash_search
inc ax
pop si
mov di,0

get_path:
mov bl,es:[si]
mov PATH[di],bl
inc si
inc di
cmp si, ax
jne get_path
mov si,0

get_filename:
mov bl,FILENAME[si]
mov PATH[di],bl
inc si
inc di
cmp bl, 0
jne get_filename
	
mov si,offset PATH
	
pop es
mov bx, offset exit
mov ax, es
sub bx, ax
mov cl, 4
shr bx, cl
mov ah, 4ah
int 21H

jnc continue

cmp ax, 7
jne _err8
lea dx, ERR7
jmp write

_err8:
cmp ax, 8
jne _err9
lea dx, ERR8
jmp write

_err9:
lea dx, ERR9
jmp write

continue:

push ds
push es
	
mov word ptr PARAMETER_BLOCK[2], es
mov word ptr PARAMETER_BLOCK[4], 80h
	
mov ax,ds
mov es,ax
mov dx, offset PATH
mov bx, offset PARAMETER_BLOCK
mov TMP_SS, ss
mov TMP_SP, sp
mov ax, 4B00h
int 21h
mov ss, TMP_SS
mov sp, TMP_SP
	
pop es
pop ds
	
jnc no_aerrs

cmp ax, 1
jne _aerr2
lea dx, AERR1
jmp write

_aerr2:
cmp ax, 2
jne _aerr5
mov ax,ds
mov es,ax
lea dx, FILE
call PUTS
lea dx, PATH
call PUTS
lea dx, NOT_FOUND
jmp write

_aerr5:
cmp ax, 5
jne _aerr8
lea dx, AERR5
jmp write

_aerr8:
cmp ax, 8
jne _aerr10
lea dx, AERR8
jmp write

_aerr10:
cmp ax, 10
jne _aerr11
lea dx, AERR10
jmp write

_aerr11:
lea dx, AERR11
jmp write

no_aerrs:
mov ah,4dh
int 21h

cmp ah, 0
je zero

cmp ah, 1
jne two
mov si, offset EXITCODE1
add si, 32
call BYTE_TO_DEC	
lea dx, EXITCODE1
jmp write

two:
cmp ah, 2
jne three
lea dx, EXITCODE2
jmp write

three:
lea dx, EXITCODE3
jmp write

zero:	
mov si, offset EXITCODE0
add si, 25
call BYTE_TO_DEC
lea dx, EXITCODE0

write:
call PUTS
mov ah, 4ch
int 21h

exit:	
MAIN ENDP
CODE ENDS
END MAIN 
