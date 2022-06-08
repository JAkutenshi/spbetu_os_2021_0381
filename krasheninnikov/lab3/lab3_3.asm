mainer SEGMENT
   ASSUME CS:mainer, DS:mainer, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Данные                 
a_mem db 13,10,'    Accessed memory size:      $'
e_mem db 13,10,'    Extended memory size:      $'
bytes db ' byte $'
MKB db 13,10,'MKB:0   $'
ADR db 'Adr:           $'
ADRPSP db 'PSP adr:          $'
SIZER db 'Size:        $'
SD_SC db ' SC/SD: $'  
EROR db 13,10,'Mem error!   $'
SUCCEED db 13,10,'got mem!$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
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
;-------------------------------
COUT PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
COUT ENDP
;-------------------------------

MEM_CALC PROC
   push ax
   push bx
   push cx
   push dx
   push si
   
   mov bx,10h
   mul bx
   mov bx,0ah
   xor cx,cx
NUM_CALC:
   div bx
   push dx
   inc cx
   xor dx,dx
   cmp ax,0h
   jnz NUM_CALC
   
print_char:
   pop dx
   or dl,30h
   mov [si], dl
   inc si
   loop print_char
   
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
   ret
MEM_CALC ENDP
;-------------------------------
Write_MKB PROC
   push ax
   push bx
   push cx
   push dx
   push si
   
   mov ah,52h
   int 21h
   mov ax,es:[bx-2]
   mov es,ax
   xor cx,cx

   inc cx
par_MKB:
   lea si, MKB
   add si, 7
   mov al,cl
   push cx
   call BYTE_TO_DEC
   lea dx, MKB
   call COUT

   mov ax,es
   lea di,ADR
   add di,12
   call WRD_TO_HEX
   lea dx,ADR
   call COUT

   xor ah,ah
   mov al,es:[0]
   push ax
   mov ax,es:[1]
   lea di, ADRPSP
   add di, 15
   call WRD_TO_HEX
   lea dx, ADRPSP
   call COUT
   mov ax,es:[3]  
   lea si,SIZER
   add si, 6
   call MEM_CALC
   lea dx,SIZER
   call COUT
   xor dx, dx
   lea dx , SD_SC 
   call COUT
   mov cx,8
   xor di,di
   
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
   cmp al,5Ah 
   je exit
   cmp al,4Dh 
   jne exit
   jmp par_MKB

   exit:
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
   ret
Write_MKB ENDP
;------------------------------------
delte_memary PROC
   push ax
   push bx
   push cx
   push dx
   
   lea ax, exit
   mov bx,10h
   xor dx,dx
   div bx
   inc ax
   mov bx,ax
   mov al,0
   mov ah,4Ah
   int 21h
   
   pop dx
   pop cx
   pop bx
   pop ax
   ret
delte_memary ENDP
;----------------------------------------
get_memary PROC near
   push ax
   push bx
   push dx
   
   mov bx,1000h
   mov ah,48h
   int 21h
   
   jc EROR_S
   jmp SUCCEED_S
   
EROR_S:
   lea dx,EROR
   call COUT
   JMP FINISHER
SUCCEED_S:   
   lea dx,SUCCEED
   call COUT
FINISHER:
   pop dx
   pop bx
   pop ax
   ret
get_memary ENDP
;----------------------------------------

BEGIN:
   mov ah,4ah
   mov bx,0ffffh
   int 21h
   mov ax,bx
   lea si, a_mem
   add si, 27 
   call MEM_CALC
   lea dx, a_mem
   call COUT
   lea dx,bytes
   call COUT
   call delte_memary
   call get_memary
   mov  AL,30h
   out 70h,AL
   in AL,71h
   mov BL,AL
   mov AL,31h
   out 70h,AL
   in AL,71h
   mov bh,al
   mov ax,bx
   lea si,e_mem
   add si, 27
   call MEM_CALC
   lea dx,e_mem
   call COUT
   lea dx,bytes
   call COUT
   call Write_MKB
   xor AL,AL
   mov AH,4Ch
   int 21H
mainer ENDS
END START