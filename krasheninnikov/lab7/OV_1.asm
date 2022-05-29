CODE SEGMENT
ASSUME CS:CODE, DS:NOTHING, SS:NOTHING, ES:NOTHING


MAIN PROC FAR
	push ax
	push dx
	push ds
	push di
	mov ax,cs
	mov ds,ax
	mov di, offset STR_OVL
	add di, 19 ;!
	call WRD2HEX
	mov dx, offset STR_OVL
	call PRINT_STR
	pop di
	pop ds
	pop dx
	pop ax
	retf
MAIN ENDP

STR_OVL db 'OV_1 ADDRESS:       ',13,10,'$' ;ovl

TETR2HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR2HEX ENDP

BYTE2HEX PROC near

   push CX
   mov AH,AL
   call TETR2HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR2HEX
   pop CX
   ret
BYTE2HEX ENDP

WRD2HEX PROC near

   push BX
   mov BH,AH
   call BYTE2HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE2HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD2HEX ENDP

PRINT_STR PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
PRINT_STR ENDP
CODE ENDS
END MAIN
