TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN

; ������
PC_TYPE db 'IBM PC type: PC', 0Dh, 0Ah, '$'
XT_TYPE db 'IBM PC type: PC/XT', 0Dh, 0Ah, '$'
AT_TYPE db 'IBM PC type: AT or PS2 (50 or 60)', 0Dh, 0Ah, '$'
PS_2_30 db 'IBM PC type: PS2 30', 0Dh, 0Ah, '$'
PS_2_80 db 'IBM PC type: PS2 80', 0Dh, 0Ah, '$'
JR_TYPE db 'IBM PC type: P�jr', 0Dh, 0Ah, '$'
PC_CONVERT db 'IBM PC type: PC Convertible', 0Dh, 0Ah, '$'
UNDEF db 'Undefined IBM PC type code:   h', 0Dh, 0Ah, '$'

VER db 'MS-DOS version:  .  ', 0Dh, 0Ah, '$'
OEM db 'OEM serial number:   ', 0Dh, 0Ah, '$'
USER db 'User serial number:       h$'

; ���������
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
;-------------------------------
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
;--------------------------------------------------
BYTE_TO_DEC PROC near
; ������� � 10�/�, SI - ����� ���� ������� �����
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
print proc near
   mov AH,09h
   int 21h
   ret
print endp

pc_type_defenition proc near
   mov ax, 0f000h 
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0FFh
	je pc
	cmp al, 0FEh
	je pc_xt
	cmp al, 0FBh
	je pc_xt
	cmp al, 0FCh
	je pc_at
	cmp al, 0FAh
	je ps30
	cmp al, 0F8h
	je ps80
	cmp al, 0FDh
	je pcjr
	cmp al, 0F9h
	je pc_convertible

   call BYTE_TO_HEX
	mov bx, offset UNDEF
	mov [bx+28], ax
	mov dx, offset UNDEF
   jmp print_type

pc:
	mov dx, offset PC_TYPE
	jmp print_type

pc_xt:
	mov dx, offset XT_TYPE
	jmp print_type

pc_at:
	mov dx, offset AT_TYPE
	jmp print_type

ps30:
	mov dx, offset PS_2_30
	jmp print_type

ps80:
	mov dx, offset PS_2_80
	jmp print_type

pcjr:
	mov dx, offset JR_TYPE
	jmp print_type

pc_convertible:
	mov dx, offset PC_CONVERT

print_type:
	call print
	ret
pc_type_defenition endp

version_defenition proc near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset VER
	add si, 16
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 3
	call BYTE_TO_DEC
	mov dx, offset VER
	call print
   
	mov si, offset OEM
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset OEM
	call print
	
	mov di, offset USER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER
	call print
	ret
version_defenition endp

; ���
BEGIN:
   call pc_type_defenition
   call version_defenition

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START 