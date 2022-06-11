O1 SEGMENT
	ASSUME CS:O1, DS:NOTHING, SS:NOTHING, ES:NOTHING
	
	
MAIN PROC FAR
	push ax
	push dx
	push ds
	push di
	
	mov ax,cs
	mov ds,ax
	lea dx, STR_LOAD
	call WRITE_STRING
	
	lea di, STR_SEG_ADRESS
	add di, 19
	mov ax, cs
	call WRD_TO_HEX
	
	lea dx, STR_SEG_ADRESS
	call WRITE_STRING
	
	pop di
	pop ds
	pop dx
	pop ax
	
	RETF
MAIN ENDP

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;���� � AL ����������� � ��� ������� ����. ����� � AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;� AL ������� �����
   pop CX ;� AH �������
   ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;������� � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
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

WRITE_STRING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITE_STRING ENDP

STR_LOAD db 'O1.ovl is loaded!',13,10,'$'
STR_SEG_ADRESS db 'Segment adress:        ',13,10,'$'

O1 ENDS
END MAIN