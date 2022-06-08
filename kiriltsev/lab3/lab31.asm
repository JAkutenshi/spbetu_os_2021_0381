text SEGMENT
   assume cs:text, ds:text, es:nothing, ss:nothing
   ORG 100H

start_point: jmp code_start
;------------------------------------------------------------
AMS db 13,10,'AMS:       $'
EMS db 13,10,'EMS:       $'
units db ' byte(s)$'
MCB_number db 13,'MCB:0   $'
HEX_adr db 'Adress:        $'
PSP_adr db 'PSP:       $'
size_in_pars db 'Paragraphs:        $'
sys_data_or_code db ' System Data/Code: $'
endl db ' ', 13, 10, '$'  
;-----------------------------------------------------
TETR_TO_HEX proc near
   and al,0Fh
   cmp al,09
   jbe next
   add al,07
next:
   add al,30h
   ret
TETR_TO_HEX endp
;-------------------------------

BYTE_TO_HEX proc near
;байт в al переводится в два символа шест. числа в ax
   push cx
   mov ah,al
   call TETR_TO_HEX
   xchg al,ah
   mov CL,4
   shr al,CL
   call TETR_TO_HEX ;в al старшая цифра
   pop cx ;в ah младшая
   ret
BYTE_TO_HEX endp

;-------------------------------

WRD_TO_HEX proc near
;перевод в 16 с/с 16-ти разрядного числа
; в ax - число, DI - адрес последнего символа
   push BX
   mov BH,ah
   call BYTE_TO_HEX
   mov [DI],ah
   dec DI
   mov [DI],al
   dec DI
   mov al,BH
   call BYTE_TO_HEX
   mov [DI],ah
   dec DI
   mov [DI],al
   pop BX
   ret
WRD_TO_HEX endp

;--------------------------------------------------

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

get_MCB proc
   push ax
   push bx
   push cx
   push dx
   push si
   
   mov ah, 52h
   int 21h
   mov ax, es:[bx-2]
   mov es, ax
   mov cx, 0
   inc cx

   next_paragraph:
   	
      lea si, MCB_number
   	add si, 7
   	mov al,cl

   	push cx
   	
      call BYTE_TO_DEC
   	lea dx, MCB_number
   	call printer

   	mov ax,es
   	lea di,HEX_adr
   	add di,12
   	call WRD_TO_HEX

   	lea dx,HEX_adr
   	call printer

   	mov ah, 0
   	mov al,es:[0]
   	push ax
   	mov ax,es:[1]
   	lea di, PSP_adr
   	add di, 8
   	call WRD_TO_HEX

   	lea dx, PSP_adr
   	call printer

   	mov ax,es:[3]	
   	lea si, size_in_pars
   	add si, 12
   	call size_calc

   	lea dx,size_in_pars
   	call printer

   	mov dx, 0
   	lea dx, sys_data_or_code 
   	call printer

   	mov cx,8
   	mov di, 0
   write_char:
   	mov dl,es:[di+8]
   	mov ah,02h
   	int 21h
   	inc di
   	loop write_char
   	
   	mov ax,es:[3]	
   	mov bx,es
   	add bx,ax
   	inc bx
   	mov es,bx

   	pop ax
   	pop cx

   	inc cx
   	cmp al, 5Ah
   	je exit
   	cmp al, 4Dh 
   	jne exit
   	jmp next_paragraph

   	exit:
      pop si
      pop dx
      pop cx
      pop bx
      pop ax
   	ret
get_MCB endp
;-----------------------------------------------------------
get_extended_mem proc near

   mov al, 30h
   out 70h, al
   in al, 71h
   mov bl, al
   mov al, 31h
   out 70h, al
   in al, 71h
   
   mov bh, al
   mov ax, bx

   lea si, EMS
   add si, 7
   call size_calc

   lea dx, EMS
   call printer

   lea dx, units
   call printer

   ret

get_extended_mem endp
;-----------------------------------------------------------
get_accessible_mem proc near

   mov ah, 4ah
   mov bx, 0ffffh
   int 21h

   mov ax, bx
   lea si, AMS
   add si, 7
   call size_calc

   lea dx, AMS
   call printer

   lea dx, units
   call printer

   ret
get_accessible_mem endp
;------------------------------------------------------------

size_calc proc
   push ax
   push bx
   push cx
   push dx
   push si
   
   mov bx, 10h
   mul bx
   mov bx, 0Ah
   mov cx, 0

get_next_digit:
   div bx
   push dx
   inc cx
   mov dx, 0
   cmp ax, 0 
   jnz get_next_digit
   
write_symbol:
   pop dx
   or dl, 30h
   mov [si], dl
   inc si
   loop write_symbol
   
   pop si
   pop dx
   pop cx
   pop bx
   pop ax

   ret

size_calc endp
;-------------------------------
code_start:
   
   call get_extended_mem
   call get_accessible_mem

   lea dx, endl
   call printer
   call printer
   
   call get_MCB

   mov al, 0
   mov ah,4Ch
   int 21h

text ends
end start_point