aStack segment stack
	dw 256 dup(?)   
aStack ends 

data segment
	ovl1 db 'OVL1.exe', 0
	ovl2 db 'OVL2.exe', 0

	err_2 db 'File not found', 13, 10, '$'
	err_3 db 'Path error!', 13, 10, '$' 
	err_7 db 'MCB has bee destroyed', 13,10, '$' 
	err_8 db 'Isnt enough memory', 13, 10, '$'
	err_9 db 'Invalid MB address', 13,10, '$' 

	err_1 db 'Function number error', 13, 10, '$'
	err_4 db 'Too many open files', 13,10, '$' 
  	err_5 db 'Disk errror', 13, 10, '$'
	err_10 db 'Environment error', 13, 10, '$'

	alloc_err db 'Not enough memory', 13,10, '$' 
	
	nl db ' ',0DH, 0AH,'$'
	PB dw 2 dup()
	path db 50 dup(0)
    buffer db 43 dup(0)
	overlay_address dd 0

data ends

code segment
	assume cs:code, ds:data, ss:aStack

;-----------------------------
printer proc near
	mov ah,9h
	int 21h
	ret
printer endp
;------------------------------

mem_resize proc near
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
	
	jns normal
	mov cx, 1
	lea dx, err_7
   	cmp ax, 7
  	je mem_status_print
   	lea dx, err_8
   	cmp ax, 8
   	je mem_status_print
   	lea dx, err_9
   	cmp ax, 9
   	je mem_status_print
   	jmp mem_resize_end

mem_status_print:
	call printer
normal:
	mov cx, 0
mem_resize_end:
	pop dx
	pop ax
	pop bx
	ret
mem_resize ENDP
;---------------------------------

get_resident_path proc near
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
	mov path[di], bl
	inc si
	inc di
	cmp si, ax
	jne path_dir
	
	pop si
path_file:
	mov bl, [si]
	mov path[di], bl
	inc si
	inc di
	cmp bl, 0
	jne path_file
	pop ax
	pop es
	ret
get_resident_path ENDP
;--------------------------------------	
overlay_initSIZE proc near	
	push dx
	push ax
	mov dx, offset buffer
	mov ah, 1ah
	int 21h
	
	mov cx, 0
	mov dx, offset path
	mov ah, 4eh
	int 21h
	
	jnc good
	mov cx, 1
	cmp ax, 2
	jne err3
	mov dx, offset err_2
	CALL printer
	jmp end_oversize
err3:
	mov dx, offset err_3
	CALL printer
	jmp end_oversize

good:	
	mov ax, word ptr buffer[1Ah]
	mov dx, word ptr buffer[1Ah+2]
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
overlay_initSIZE ENDP	
;---------------------------------------------------
alloc_mem proc near 
	push bx
	push dx
	mov bx, ax
	mov ah, 48h
	int 21h
	jnc good_alloc
	mov dx, offset alloc_err
	call printer
	mov cx, 1
	jmp end_alloc
good_alloc:
	mov cx, 0
	mov PB[0], ax
	mov PB[2], ax
end_alloc:
	pop dx
	pop bx
	ret
alloc_mem ENDP	
;---------------------------------------------------
overlay_init proc near	
	push es
	push ax
	push bx
	push dx
		
	mov dx, offset path
	mov ax, ds
	mov es, ax
	mov bx, offset PB
	mov ax, 4B03h
	int 21h
		
	jnc good_call
	
	cmp ax, 1
	jne launch_err_2
	mov dx, offset err_1
	call printer
	jmp end_call_program
launch_err_2:
	cmp ax, 2
	jne launch_err_3
	mov dx, offset err_2
	call printer
	jmp end_call_program
launch_err_3:
	cmp ax, 3
	jne launch_err_4
	mov dx, offset err_3
	call printer
	jmp end_call_program
launch_err_4:
	cmp ax, 4
	jne launch_err_5
	mov dx, offset err_4
	call printer
	jmp end_call_program
launch_err_5:
	cmp ax, 5
	jne launch_err_8
	mov dx, offset err_5
	call printer
	jmp end_call_program
launch_err_8:
	cmp ax, 8
	jne launch_err_10
	mov dx, offset err_8
	call printer
	jmp end_call_program
launch_err_10:
	mov dx, offset err_10
	call printer
	jmp end_call_program
	
good_call:
	mov ax, PB[2]
	mov word ptr overlay_address+2, ax 
	call overlay_address
	
	mov es,ax
	mov ah, 49h
	int 21h
	
end_call_program:
	pop dx
	pop bx
	pop ax
	pop es
	ret
overlay_init ENDP 	

;-----------------------------
MAIN proc FAR
	mov ax, data
	mov ds, ax
	push es
	call mem_resize
	cmp cx, 0
	jne end_main
	
	mov si, offset ovl1
	call get_resident_path	
	call overlay_initSIZE
	cmp cx, 0
	jne call_over2
	call alloc_mem
	cmp cx, 0
	jne call_over2
	call overlay_init
	
call_over2:
	pop es
	mov dx, offset nl
	call printer
	mov si,offset ovl2
	call get_resident_path	
	call overlay_initSIZE
	cmp cx, 0
	jne end_main
	call alloc_mem
	cmp cx, 0
	jne end_main
	call overlay_init
	
end_main:	
	xor al, al
	mov ah, 4ch
	int 21h  
end_prm:
MAIN ENDP
code ends
END MAIN 