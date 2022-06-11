aStack segment stack
  dw  264 dup(?)
aStack ends

data segment
	PB db 14 dup() ; Parameter Block
	
	mem_status_7 db 'CMB has been destroyed', 13, 10, '$'
  mem_status_8 db 'Is not enough memory for function', 13, 10, '$'
  mem_status_9 db 'Memory address is invalid', 13, 10, '$'

	keep_ss dw 0
	keep_sp dw 0

	resident_file db "lab2.com", 0
	resident_path db 50 dup(0)

	err_1 db 'Function number error', 13, 10, '$'
  err_2 db 'File not found', 13, 10, '$'
  err_5 db 'Disk errror', 13, 10, '$'
  err_8 db 'Low memory error', 13, 10, '$'
  err_10 db 'Environment error', 13, 10, '$'
  err_11 db 'Format error', 13, 10, '$'
 	
  termination_0 db 13, 10, 'Successful execution:             ', 13, 10, '$'
  termination_1 db 'Ctrl-Break termination', 13, 10, '$'
  termination_2 db 'Device err termination', 13, 10, '$'
  termination_3 db '31h termination', 13, 10, '$'
data ends

code segment
	assume ds:data, CS:code, SS:aStack	

;-------------------------------

printer proc near
	mov ah,9h
	int 21h
	ret
printer endp
;-------------------------------

BYTE_TO_DEC proc near
	push CX
	push DX
	xor ah,ah
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
BYTE_TO_DEC endp
;----------------------------

get_resident_path proc near
	push es
	push si
	push ax
	sub si, si
	mov es, es:[2Ch]
	
cycle:
	mov al, es:[si]
	inc si
	cmp al, 0
	jne cycle
	mov al, es:[si]
	cmp al, 0
	jne cycle
	
	add si, 3	
	push si
add_slash:
	cmp byte ptr es:[si], '\'
	jne next
	mov ax, si
next:
	inc si
	cmp byte ptr es:[si], 0
	jne add_slash
	inc ax
	pop si
	mov di, 0

get_fdir:	
	mov bl, es:[si]
	mov resident_path[di], bl
	inc si
	inc di
	cmp si, ax
	jne get_fdir
	
	mov si, 0
get_fname:
	mov bl, resident_file[si]
	mov resident_path[di], bl
	inc si
	inc di
	cmp bl, 0
	jne get_fname
	pop ax
	pop si
	pop es
	ret
get_resident_path endp
;-------------------------------

mem_resize proc near
   push ax
   push bx
   
   lea bx, end_prm
   mov ax, es
   sub bx, ax
   ;mov ax, bx
   shr bx, 1
   shr bx, 1
   shr bx, 1
   shr bx, 1
   inc bx
   mov ah, 4Ah
   int 21h

   jnc mem_resize_end
   
   lea dx, mem_status_7
   cmp ax, 7
   je mem_status_print
   lea dx, mem_status_8
   cmp ax, 8
   je mem_status_print
   lea dx, mem_status_9
   cmp ax, 9
   je mem_status_print
   jmp mem_resize_end
   
mem_status_print:
   call printer
   
mem_resize_end:   
   pop bx
   pop ax
   ret
mem_resize endp
;-------------------------------

resident proc near

   push ds
   push es
   mov word ptr PB[2], es
   mov word ptr PB[4], 80h
	
	
   mov ax,ds
   mov es,ax
   mov dx,offset resident_path
   mov bx,offset PB
   mov keep_ss, ss
   mov keep_sp, sp
   mov ax, 4B00h
   int 21h
   mov ss, keep_ss
   mov sp, keep_sp
   pop es
   pop ds
	
   jnc program_exit
   ;mov cx, 0
	
   lea dx, err_1
   cmp ax, 1
   je print_message
   lea dx, err_2
   cmp ax, 2
   je print_message   
   lea dx, err_5
   cmp ax, 5
   je print_message   
   lea dx, err_8
   cmp ax, 8
   je print_message   
   lea dx, err_10
   cmp ax, 10
   je print_message
   lea dx, err_11
   cmp ax, 11
   je print_message
   
program_exit:
   mov ah, 4dh
   int 21h	
   mov dx, offset termination_1
   cmp ah, 1
   je print_message
   mov dx, offset termination_2
   cmp ah, 2
   je print_message
   mov dx, offset termination_3
   cmp ah, 3
   je print_message	
   mov si, offset termination_0
   add si, 34
   call BYTE_TO_DEC
   mov dx, offset termination_0
   jmp print_message

print_message:
   call printer

end_call_program:
	ret
resident endp
;-------------------------------

Main proc far
begin:
	mov ax, data  
	mov ds, ax	
	call get_resident_path
	call mem_resize
	call resident

end_main:
	sub al, al
	mov ah, 4Ch
	int 21H 
end_prm:
Main      endp
code      ends
end Main 