AStack    SEGMENT  STACK
          DW 128 DUP(?)   
AStack    ENDS

DATA  SEGMENT  
	T_PC db  '��� PC: PC',0DH,0AH,'$'
	T_PC_XT db '��� PC: PC/XT',0DH,0AH,'$'
	T_AT db  '��� PC: AT',0DH,0AH,'$'
	T_PS2_M30 db '��� PC: PS2 ������ 30',0DH,0AH,'$'
	T_PS2_M50_60 db '��� PC: PS2 ������ 50 ��� 60',0DH,0AH,'$'
	T_PS2_M80 db '��� PC: PS2 ������ 80',0DH,0AH,'$'
	T_P�_JR db '��� PC: P�jr',0DH,0AH,'$'
	T_PC_CONV db '��� PC: PC Convertible',0DH,0AH,'$'
	T_NOT db '��� PC: ����।����, ���:  ',0DH,0AH,'$'
	VERSION db '����� MS-DOS:  .  ',0DH,0AH,'$'
	SERIAL_NUMBER_OEM db  '��਩�� ����� OEM:   H',0DH,0AH,'$'
	SERIAL_USER_NUMBER db '��਩�� ����� ���짮��⥫�:       H$'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack
   ; ��楤���
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
;���� � AL ��ॢ������ � ��� ᨬ���� ���. �᫠ � AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;� AL ����� ���
   pop CX ;� AH ������
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;��ॢ�� � 16 �/� 16-� ࠧ�來��� �᫠
; � AX - �᫮, DI - ���� ��᫥����� ᨬ����
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
; ��ॢ�� � 10�/�, SI - ���� ���� ����襩 ����
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
OUTPUT PROC near
   mov AH,09h
   int 21h
   ret
OUTPUT ENDP

TYPE_PC PROC near
	mov ax, 0f000h ; ����砥� ����� ������ 
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh ; ��稭��� ��ࠢ������
	je pc
	cmp al, 0feh
	je pc_xt
	cmp al, 0fbh
	je pc_xt
	cmp al, 0fch
	je pc_at
	cmp al, 0fah
	je ps2_m30
	cmp al, 0f8h
	je ps2_m80
	cmp al, 0fdh
	je pc_jr
	cmp al, 0f9h
	je pc_conv
	je type_not
pc:
	mov dx, offset T_PC
	jmp t_output
pc_xt:
	mov dx, offset T_PC_XT
	jmp t_output
pc_at:
	mov dx, offset T_AT
	jmp t_output
ps2_m30:
	mov dx, offset T_PS2_M30
	jmp t_output
ps2_m80:
	mov dx, offset T_PS2_M80
	jmp t_output
pc_jr:
	mov dx, offset T_P�_JR
	jmp t_output
pc_conv:
	mov dx, offset T_PC_CONV
	jmp t_output 
type_not:
	mov di, offset T_NOT
	add di, 25
	mov al, bh
	call BYTE_TO_HEX
	mov [di], ax
	mov dx, offset T_NOT
	jmp t_output 
t_output:
		call OUTPUT
	ret
TYPE_PC ENDP

SYSTEM_VERSION PROC near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset VERSION
	add si, 15
	call BYTE_TO_DEC
    pop ax
    mov al, ah
    add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSION
	call OUTPUT
	
	mov di, offset SERIAL_NUMBER_OEM
	add di, 20
	mov al, bh
	call BYTE_TO_HEX
	mov [di], ax
	mov dx, offset SERIAL_NUMBER_OEM
	call OUTPUT
	
	mov di, offset SERIAL_USER_NUMBER
	add di, 34
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset SERIAL_USER_NUMBER
	call OUTPUT
	ret
SYSTEM_VERSION ENDP

Main PROC FAR
   sub   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX
   call TYPE_PC
   call SYSTEM_VERSION
   xor AL,AL
   mov AH,4Ch
   int 21H
Main ENDP
CODE ENDS
      END Main