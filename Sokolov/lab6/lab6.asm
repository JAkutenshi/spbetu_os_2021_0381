aStack segment stack
   dw 200 dup(?)   
aStack ends

data segment
   PB             dw 0 ;сегментный адрес среды
                  dd 0 ;сегмент и смещение командной строки
                  dd 0 ;сегмент и смещение FCB 
                  dd 0 ;сегмент и смещение FCB 
                  
   keep_ss dw 0
   keep_sp dw 0
   
   resident_file db 'lb2.COM$'
   resident_path db 50 dup (0)
   
   mem_status_7 db 'CMB has been destroyed', 13, 10, '$'
   mem_status_8 db 'Is not enough memory for function', 13, 10, '$'
   mem_status_9 db 'Memory address is invalid', 13, 10, '$'
   
   err_1 db 'Function number error', 13, 10, '$'
   err_2 db 'File not found', 13, 10, '$'
   err_5 db 'Disk errror', 13, 10, '$'
   err_8 db 'Low memory error', 13, 10, '$'
   err_10 db 'Environment error', 13, 10, '$'
   err_11 db 'Format error', 13, 10, '$'
                        
   termination_0 db 'Successful execution:        ', 13, 10, '$'
   termination_1 db 'Ctrl-Break termination', 13, 10, '$'
   termination_2 db 'Device err termination', 13, 10, '$'
   termination_3 db '31h termination', 13, 10, '$'

data ends

code segment
   assume cs:code,  ds:data,  ss:aStack

;--------------------------------
BYTE_TO_DEC proc near
; перевод в 10с/с, si - адрес поля младшей цифры
   push cx
   push dx
   xor ah,ah
   xor dx,dx
   mov cx,10
loop_bd:
   div cx
   or dl,30h
   mov [si],dl
   dec si
   xor dx,dx
   cmp ax,10
   jae loop_bd
   cmp al,00h
   je end_l
   or al,30h
   mov [si],al
end_l:
   pop dx
   pop cx
   ret
BYTE_TO_DEC endp
;-------------------------------
printer proc near
   push ax
   mov ah, 09h
   int 21h
   pop ax
   ret
printer endp
;-------------------------------

mem_resize proc
   push ax
   push bx
   
   lea bx, host_end
   mov ax, es
   sub bx, ax
   mov ax, bx
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
;---------------------------------
PB_config proc near
   mov ax, es:[2ch]
   mov PB, ax
   mov PB+2, es
   mov PB+4, 80h
   ret
PB_config endp
;---------------------------------
get_path proc near
   push dx
   push di
   push si
   push es
   
   sub di, di
   mov es, es:[2ch]
   
next:
   mov dl, es:[di]
   cmp dl, 0h
   je last
   inc di
   jmp next
      
last:
   inc di
   mov dl, es:[di]
   cmp dl, 0h
   jne next
   
   add di, 3
   mov si, 0
   
write_path:
   mov dl, es:[di]
   cmp dl, 0
   je clear_filename
   mov resident_path[si], dl
   inc di
   inc si
   jmp write_path

clear_filename:
   dec si
   cmp resident_path[si], '\'
   je set_filename_init
   jmp clear_filename
   
set_filename_init:
   mov di, -1

set_filename:
   inc si
   inc di
   mov dl,resident_file[di]
   cmp dl,'$'
   je get_path_end
   mov resident_path[si],dl
   jmp set_filename
   
get_path_end:
   pop es
   pop si
   pop di
   pop dx
   ret
get_path endp
;---------------------------------
resident proc near
   push ds
   push es
   
   mov keep_sp, sp
   mov keep_ss, ss
   mov ax, ds
   mov es, ax
   
   lea dx, resident_path
   lea bx, PB
   mov ax, 4B00h
   int 21h
   
   mov ss, keep_ss
   mov sp, keep_sp
   
   pop es
   pop ds  
   
   push dx
   push ax
   
   mov dl, 10
   mov ah, 2
   int 21h

   mov dl, 13
   mov ah, 2
   int 21h  
   
   pop ax
   pop dx

   call get_status
   ret
resident endp
;---------------------------------
get_status proc
   push dx
   push ax
   push si
   
   jc bad_exec
 
   mov ax, 4D00h
   int 21h

   lea dx, termination_1
   cmp ah, 1
   je print_message
   lea dx, termination_2
   cmp ah, 2
   je print_message
   lea dx, termination_3
   cmp ah, 3
   je print_message
   cmp ah, 0
   jne get_status_end
   
   lea dx, termination_0
   mov si, dx
   add si, 28  
   call BYTE_TO_DEC
 
   jmp print_message
   
bad_exec: 
   
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
   
print_message:
   call printer

get_status_end:   
   pop si
   pop ax
   pop si
   ret
get_status endp
;---------------------------------
Main proc far
   sub   ax, ax
   push  ax
   mov   ax, data
   mov   ds, ax
   
   call mem_resize
   call PB_config
   call get_path
   call resident
   
   sub al, al
   mov ah, 4Ch
   int 21h

Main endp
host_end:
code ends
end Main