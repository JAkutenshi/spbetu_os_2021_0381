AStack    SEGMENT  STACK
          DW  200 DUP(?)
AStack    ENDS

DATA      SEGMENT
BLOCK_OF_PARAMENRS db 14 dup()
ERR07 db 'Sorry, memory control block destroyed', 13,10, '$' 
ERR08 db   'Sorry, not enough memory', 13,10, '$' 
ERR09 db 'Sorry, invalid memory block address', 13,10, '$' 
PATH db 50 dup(0)
OLD_SS    dw 0
OLD_SP    dw 0
FILE_NAME db "LAB2.com", 0
LAUNCH_ERR01 db 'Function number is not correct', 13,10, '$' 
LAUNCH_ERR02 db 'File not found', 13,10, '$' 
LAUNCH_ERR05 db 'Disk error', 13,10, '$' 
LAUNCH_ERR08 db 'Not enough memory', 13,10, '$' 
LAUNCH_ERR10 db 'Wrong environment string', 13,10, '$' 
LAUNCH_ERR11 db 'Incorrect format', 13,10, '$' 
EXITCODE0 db 13,10,'Normal termination with code: 000', 13,10, '$' 
EXITCODE1 db 'Termination with Ctrl-Break', 13,10, '$' 
EXITCODE2 db 'Device error termination', 13,10, '$' 
EXITCODE3 db 'Termination by function 31h', 13,10, '$' 
S_ENTER db ' ',0DH, 0AH,'$'

DATA      ENDS

CODE      SEGMENT
        ASSUME DS:DATA, CS:CODE, SS:AStack	

OUTPUT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
OUTPUT ENDP

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

CALL_PATH PROC NEAR
	push es
	push si
	push ax
	sub si, si
	mov es, es:[2Ch]
	
path_loop:
	mov al,es:[si]
	inc si
	cmp al,0
	jne path_loop
	mov al,es:[si]
	cmp al,0
	jne path_loop
	
	add si,3	
	push si
path_slash:
	cmp byte ptr es:[si],'\'
	jne next
	mov ax,si
next:
	inc si
	cmp byte ptr es:[si],0
	jne path_slash
	inc ax
	pop si
	mov di,0

path_dir:	
	mov bl,es:[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp si, ax
	jne path_dir
	
	mov si, 0
path_file:
	mov bl,FILE_NAME[si]
	mov PATH[di],bl
	inc si
	inc di
	cmp bl, 0
	jne path_file
	pop ax
	pop si
	pop es
	ret
CALL_PATH ENDP

CALL_FREE_MEMORY PROC NEAR
	push bx
	push ax
	push dx
	mov bx, offset end_prm
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	inc bx
	mov ah, 4ah
	int 21H
	
	jns end_free_memory
	cmp ax, 7
	jne err_8
	mov dx, offset ERR07
	call OUTPUT
	jmp end_free_memory
	
err_8:
	cmp ax, 8
	jne err_9
	mov dx, offset ERR08
	call OUTPUT
	jmp end_free_memory

err_9:
	cmp ax, 9
	jne end_free_memory
	mov dx, offset ERR07
	call OUTPUT

end_free_memory:
	pop dx
	pop ax
	pop bx
	ret
CALL_FREE_MEMORY ENDP

CALL_PROGRAM PROC NEAR

	push ds
	push es
	mov word ptr BLOCK_OF_PARAMENRS[2], es
	mov word ptr BLOCK_OF_PARAMENRS[4], 80h
	
	
	mov ax,ds
	mov es,ax
	mov dx,offset PATH
	mov bx,offset BLOCK_OF_PARAMENRS
	mov OLD_SS, ss
	mov OLD_SP, sp
	mov ax, 4B00h
	int 21h
	mov ss, OLD_SS
	mov sp, OLD_SP
	pop es
	pop ds
	
	
	jnc program_exit
	
	cmp ax, 1
	jne launch_err_2
	mov dx, offset LAUNCH_ERR01
	call OUTPUT
	jmp end_call_program
	
launch_err_2:
	cmp ax, 2
	jne launch_err_5
	mov dx, offset LAUNCH_ERR02
	call OUTPUT
	jmp end_call_program
launch_err_5:
	cmp ax, 5
	jne launch_err_8
	mov dx, offset LAUNCH_ERR05
	call OUTPUT
	jmp end_call_program
launch_err_8:
	cmp ax, 8
	jne launch_err_10
	mov dx, offset LAUNCH_ERR08
	call OUTPUT
	jmp end_call_program
launch_err_10:
	cmp ax, 10
	jne launch_err_11
	mov dx, offset LAUNCH_ERR10
	call OUTPUT
	jmp end_call_program
launch_err_11:
	mov dx, offset LAUNCH_ERR11
	call OUTPUT
	jmp end_call_program
	
program_exit:
	mov ah,4dh
	int 21h	
	cmp ah,0
	je normal_end
	cmp ah, 1
	jne err_end
	mov dx, offset EXITCODE1
	call OUTPUT
	jmp end_call_program
err_end:
	cmp ah, 2
	jne f_31h_end
	mov dx, offset EXITCODE2
	call OUTPUT
	jmp end_call_program
f_31h_end:
	mov dx, offset EXITCODE3
	call OUTPUT
	jmp end_call_program
normal_end:	
	mov si, offset EXITCODE0
	add si, 34
	call BYTE_TO_DEC
	mov dx, offset EXITCODE0
	call OUTPUT
	
end_call_program:
	ret
CALL_PROGRAM ENDP

Main  PROC  FAR
begin:
	mov ax, DATA  
	mov ds, ax	
	call CALL_PATH
	call CALL_FREE_MEMORY
	call CALL_PROGRAM
	
	
end_main:	; Выход в DOS
	sub al, al
	mov AH,4Ch
	int 21H 
end_prm:
Main      ENDP
CODE      ENDS
          END Main