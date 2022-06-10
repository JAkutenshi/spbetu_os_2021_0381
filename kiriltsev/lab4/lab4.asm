aStack segment stack
   dw 64 dup(?)   
aStack ends

data segment
   unload_key db 0
   in_use db 0

   int_not_loaded  db 'Interruption is not loaded.', 10, 13, '$'
   int_unloaded db 'Interruption unloaded successfully.', 10, 13, '$' 
   int_loaded db 'Interruption loaded successfully.', 10, 13, '$'
   int_in_use db 'Interruption is loaded already.', 10, 13, '$'

data ends

code segment
   assume cs:code,  ds:data,  ss:aStack

;-------------------------------		 
custom_interruption proc far
	jmp custom_int_start
	
	int_id dw 8f17h

	psp dw ?
	keep_ip dw 0
	keep_cs dw 0
	keep_ss dw ?
	keep_sp dw ?
	keep_ax dw ?
	
	cnt db 'interruption count: 0000' , '$'
						
	int_stack dw 32 dup (?)
	int_stack_end dw ?
	
	custom_int_start:

	   	mov keep_ss, ss
	   	mov keep_sp, sp
	   	mov keep_ax, ax

	   	mov ax, cs
	   	mov ss, ax
	   	mov sp, offset int_stack_end

	   	push bx
	   	push cx
	   	push dx
	   	
	   	mov ah, 3
	   	mov bh, 0
	   	int 10h
      
	    push dx
	   	mov ah, 0Bh
	   	mov bh, 1
	   	mov bl, 025h
	   	
	   	mov ah, 2
	   	mov bh, 0
	   	mov dh, 2
	   	mov dl, 40
	   	int 10h
	   	
	   	push si
	   	push cx
	   	push ds
	   	push bp
	   	
	   	mov ax, seg cnt
	   	mov ds, ax
	   	mov si, offset cnt
	   	add si, 20
	   	mov cx, 4

	int_loop:

	   	mov bp, cx
	   	mov ah, [si+bp]
	   	inc ah
	   	mov [si+bp], ah
	   	cmp ah, 3Ah
	   	jne digit
	   	mov ah, 30h
	   	mov [si+bp], ah
	    loop int_loop 
	 
   	digit:

	   	pop bp
	   	pop ds
	   	pop cx
	   	pop si
	   	
	   	push es
	   	push bp
	   	mov ax, seg cnt
	   	mov es, ax
	   	mov ax, offset cnt
	   	mov bp, ax
	   	mov ah, 13h
	   	mov al, 0
	   	mov cx, 25
	   	mov bh, 0
	   	int 10h
	   	
	   	pop bp
	   	pop es
	   	pop dx
	   	mov ah, 2
	   	mov bh, 0
	   	int 10h

	   	pop dx
	   	pop cx
	   	pop bx
	   	
	   	mov ax,  keep_ss
	   	mov ss,  ax
	   	mov ax,  keep_ax
	   	mov sp,  keep_sp

	iret
	int_end:
custom_interruption endp			 

;----------------------------- 
printer proc near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
printer endp
;-------------------------------

is_in_use proc near
	push ax
	push si
	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov si, offset int_id
	sub si, offset custom_interruption
	mov dx, es:[bx+si]
	cmp dx, 8f17h
	jne iiu_end
	mov in_use, 1
	
	iiu_end:	
		pop si
		pop ax
		ret
is_in_use endp

;-------------------------------

int_load proc near
	push ax
	push dx
	
	call is_in_use
	cmp in_use, 1
	je in_use_right_now
	jmp int_load_start
	
in_use_right_now:
	lea dx, int_in_use
	call printer
	jmp int_load_end
  
int_load_start:
	mov ah, 35h
	mov al, 1Ch
	int 21h 
	mov keep_cs, es
	mov keep_ip, bx
	
	push ds
	lea dx, custom_interruption
	mov ax, seg custom_interruption
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	lea dx, int_loaded
	call printer
	
	lea dx, int_end
	mov cl, 4h
	shr dx, cl
	inc dx
	mov ax, cs
	sub ax, psp
	add dx, ax
	xor ax, ax
	mov ah, 31h
	int 21h
	  
int_load_end:  
	pop dx
	pop ax
	ret
int_load endp

;-------------------------------
unload_key_check proc near
	
   push ax
	mov psp, es
	mov al, es:[81h+1]
	cmp al, '/'
	jne ukc_end
	mov al, es:[81h+2]
	cmp al,  'u'
	jne ukc_end
	mov al, es:[81h+3]
	cmp al,  'n'
	jne ukc_end
	mov unload_key,  1
  
	ukc_end:
		pop ax
		ret

unload_key_check endp
;-------------------------------
int_unload proc near
	push ax
	push si
	
	call is_in_use
	cmp in_use, 1
	jne not_loaded
	jmp m_start_unload
	
not_loaded:
	lea dx, int_not_loaded
	call printer
	jmp int_unload_end
	
	
m_start_unload:
	clI
	push ds
	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov si, offset keep_ip
	sub si, offset custom_interruption
	mov dx, es:[bx+si]
	mov ax, es:[bx+si+2]
	mov ds, ax
	mov ah, 25h
	mov al,  1Ch
	int 21h
	pop ds
	mov ax, es:[bx+si-2]
	mov es, ax
	push es
	
	mov ax, es:[2ch]
	mov es, ax
	mov ah, 49h
	int 21h
	
	pop es
	mov ah, 49h
	int 21h
	STI
	
	lea dx, int_unloaded
	call printer

	int_unload_end:	
		pop si
		pop ax
		ret
int_unload endp

;--------------------------------
Main proc far
	
	push  ds		 
	sub	ax, ax	 
	push  ax		 
	mov	ax, data				 
	mov	ds, ax

	call unload_key_check
	cmp unload_key, 1
	je init_unload
	call int_load
	jmp Main_end
	
	init_unload:
		call int_unload
	
	Main_end:  
		mov ah, 4ch
		int 21h

Main endp
code ends
END Main