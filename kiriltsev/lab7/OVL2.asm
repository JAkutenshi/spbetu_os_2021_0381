CODE SEGMENT
ASSUME cs:CODE
MAIN PROC FAR
    push ax
    push dx
    push ds
    push di

    mov ax,cs
    mov ds,ax
    mov di, offset ADDRESS
    add di, 26
    call wrd_to_hex
    mov dx, offset ADDRESS
    call OUTPUT

    pop di
    pop ds
    pop dx
    pop ax
    retf
MAIN ENDP

ADDRESS db "Address of overlay 2 : 0000h$", 13,10, '$' 

OUTPUT PROC near
   push ax
   mov AH,09h
   int 21h
   pop ax
   ret
OUTPUT ENDP

TETR_TO_HEX PROC near
   and al,0Fh
   cmp al,09
   jbe NEXT
   add al,07
NEXT: 
   add al,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
   push cx
   mov ah,al
   call TETR_TO_HEX
   xchg al,ah
   mov cl,4
   shr al,cl
   call TETR_TO_HEX 
   pop cx 
   ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
   push bx
   mov bh,ah
   call BYTE_TO_HEX
   mov [di],ah
   dec di
   mov [di],al
   dec di
   mov al,bh
   call BYTE_TO_HEX
   mov [di],ah
   dec di
   mov [di],al
   pop bx
   ret
WRD_TO_HEX ENDP

CODE ENDS
END MAIN 