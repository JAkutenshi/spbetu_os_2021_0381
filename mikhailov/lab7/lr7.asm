AStack SEGMENT STACK
	DW 256 DUP(?)   
AStack ENDS

DATA  SEGMENT
	OVER1_NAME db 'overlay1.exe', 0
	OVER2_NAME db 'overlay2.exe', 0
	ERR02 db 'Sorry, file not found', 13,10, '$' 
	ERR03 db   'Sorry, route not found', '$' 
	ERR07 db 'Sorry, memory control block destroyed', 13,10, '$' 
	ERR08 db   'Sorry, not enough memory', 13,10, '$' 
	ERR09 db 'Sorry, invalid memory block address', 13,10, '$' 
	LAUNCH_ERR01 db 'Wrong function', 13,10, '$' 
	LAUNCH_ERR02 db 'File not found', 13,10, '$' 
	LAUNCH_ERR03 db 'Route not found', 13,10, '$' 
	LAUNCH_ERR04 db 'Too many open files', 13,10, '$' 
	LAUNCH_ERR05 db 'No access', 13,10, '$' 
	LAUNCH_ERR08 db 'Too little memory', 13,10, '$' 
	LAUNCH_ERR10 db 'Wrong environment', 13,10, '$'
	ALLOCATION_ERR db 'Not enough memory', 13,10, '$' 
	
	S_ENTER db ' ',0DH, 0AH,'$'
	BLOCK_OF_PARAMENRS dw 2 dup()
	PATH db 50 dup(0)
    DTA_BUF db 43 dup(0)
	OVER_ADDRESS dd 0

DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack

WRITESTRING PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
WRITESTRING ENDP

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
	
	jns free_memory_good
	mov cx, 1
	cmp ax, 7
	jne err_8
	mov dx, offset ERR07
	call WRITESTRING
	jmp end_free_memory
	
err_8:
	cmp ax, 8
	jne err_9
	mov dx, offset ERR08
	call WRITESTRING
	jmp end_free_memory

err_9:
	cmp ax, 9
	jne end_free_memory
	mov dx, offset ERR07
	call WRITESTRING
	
free_memory_good:
	mov cx, 0

end_free_memory:
	pop dx
	pop ax
	pop bx
	ret
CALL_FREE_MEMORY ENDP
	
CALL_PATH PROC NEAR
	push es
	push ax
	push si
	sub si, si
	mov es, es:[2Ch]
	
path_loop:
	mov al,es:[si]
	inc si
	cmp al, 0
	jne path_loop
	mov al, es:[si]
	cmp al, 0
	jne path_loop
	
	add si, 3	
	push si
	
path_slash:
	cmp byte ptr es:[si],'\'
	jne next
	mov ax,si
next:
	inc si
	cmp byte ptr es:[si], 0
	jne path_slash
	inc ax
	pop si
	mov di, 0

path_dir:	
	mov bl, es:[si]
	mov PATH[di], bl
	inc si
	inc di
	cmp si, ax
	jne path_dir
	
	pop si
path_file:
	mov bl, [si]
	mov PATH[di], bl
	inc si
	inc di
	cmp bl, 0
	jne path_file
	pop ax
	pop es
	ret
CALL_PATH ENDP
	
CALL_OVERSIZE PROC NEAR	
	push dx
	push ax
	mov dx, offset DTA_BUF
	mov ah, 1ah
	int 21h
	
	mov cx, 0
	mov dx, offset PATH
	mov ah, 4eh
	int 21h
	
	jnc good
	mov cx, 1
	cmp ax, 2
	jne err3
	mov dx, offset ERR02
	CALL WRITESTRING
	jmp end_oversize
err3:
	mov dx, offset ERR03
	CALL WRITESTRING
	jmp end_oversize

good:	
	mov ax, word ptr DTA_BUF[1Ah]
	mov dx, word ptr DTA_BUF[1Ah+2]
	mov cl, 4
	shr ax, cl	
	mov cl, 12
	shl dx, cl
	add ax, dx
	add ax, 1
	mov cx, 0
end_oversize:
	pop ax
	pop dx
	ret
CALL_OVERSIZE ENDP	

CALL_ALLOCATION_MEMORY PROC NEAR 
	push bx
	push dx
	mov bx, ax
	mov ah, 48h
	int 21h
	jnc good_alloc
	mov dx, offset ALLOCATION_ERR
	call WRITESTRING
	mov cx, 1
	jmp end_alloc
good_alloc:
	mov cx, 0
	mov BLOCK_OF_PARAMENRS[0], ax
	mov BLOCK_OF_PARAMENRS[2], ax
end_alloc:
	pop dx
	pop bx
	ret
CALL_ALLOCATION_MEMORY ENDP	

CALL_OVER PROC NEAR	
	push es
	push ax
	push bx
	push dx
		
	mov dx, offset PATH
	mov ax, ds
	mov es, ax
	mov bx, offset BLOCK_OF_PARAMENRS
	mov ax, 4B03h
	int 21h
		
	jnc good_call
	
	cmp ax, 1
	jne launch_err_2
	mov dx, offset LAUNCH_ERR01
	call WRITESTRING
	jmp end_call_program
launch_err_2:
	cmp ax, 2
	jne launch_err_3
	mov dx, offset LAUNCH_ERR02
	call WRITESTRING
	jmp end_call_program
launch_err_3:
	cmp ax, 3
	jne launch_err_4
	mov dx, offset LAUNCH_ERR03
	call WRITESTRING
	jmp end_call_program
launch_err_4:
	cmp ax, 4
	jne launch_err_5
	mov dx, offset LAUNCH_ERR04
	call WRITESTRING
	jmp end_call_program
launch_err_5:
	cmp ax, 5
	jne launch_err_8
	mov dx, offset LAUNCH_ERR05
	call WRITESTRING
	jmp end_call_program
launch_err_8:
	cmp ax, 8
	jne launch_err_10
	mov dx, offset LAUNCH_ERR08
	call WRITESTRING
	jmp end_call_program
launch_err_10:
	mov dx, offset LAUNCH_ERR10
	call WRITESTRING
	jmp end_call_program
	
good_call:
	mov ax, BLOCK_OF_PARAMENRS[2]
	mov word ptr OVER_ADDRESS+2, ax 
	call OVER_ADDRESS
	
	mov es,ax
	mov ah, 49h
	int 21h
	
end_call_program:
	pop dx
	pop bx
	pop ax
	pop es
	ret
CALL_OVER ENDP 	


MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	push es
	call CALL_FREE_MEMORY
	cmp cx, 0
	jne end_main
	
	mov si, offset OVER1_NAME
	call CALL_PATH	
	call CALL_OVERSIZE
	cmp cx, 0
	jne call_over2
	call CALL_ALLOCATION_MEMORY
	cmp cx, 0
	jne call_over2
	call CALL_OVER
	
call_over2:
	pop es
	mov dx, offset S_ENTER
	call WRITESTRING
	mov si,offset OVER2_NAME
	call CALL_PATH	
	call CALL_OVERSIZE
	cmp cx, 0
	jne end_main
	call CALL_ALLOCATION_MEMORY
	cmp cx, 0
	jne end_main
	call CALL_OVER
	
end_main:	
	xor al, al
	mov ah, 4ch
	int 21h  
end_prm:
MAIN ENDP
CODE ENDS
END MAIN