TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: 
JMP BEGIN
; ДАННЫЕ
T_PC db  'Тип PC: PC',0DH,0AH,'$'
T_PC_XT db 'Тип PC: PC/XT',0DH,0AH,'$'
T_AT db  'Тип PC: AT',0DH,0AH,'$'
T_PS2_M30 db 'Тип PC: PS2 модель 30',0DH,0AH,'$'
T_PS2_M50_60 db 'Тип PC: PS2 модель 50 или 60',0DH,0AH,'$'
T_PS2_M80 db 'Тип PC: PS2 модель 80',0DH,0AH,'$'
T_PС_JR db 'Тип PC: PСjr',0DH,0AH,'$'
T_PC_CONV db 'Тип PC: PC Convertible',0DH,0AH,'$'
T_NOT db 'Тип PC: неопределен, код:  ',0DH,0AH,'$'
VERSION db 'Версия MS-DOS:  .  ',0DH,0AH,'$'
SERIAL_NUMBER_OEM db  'Серийный номер OEM:   H',0DH,0AH,'$'
SERIAL_USER_NUMBER db 'Серийный номер пользователя:       H$'
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: 
	add AL,30h
 ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
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
end_l: pop DX
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
	mov ax, 0f000h ; получаем номер модели 
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh ; начинаем стравнивать
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
	mov dx, offset T_PС_JR
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

; КОД
BEGIN:
 call TYPE_PC
 call SYSTEM_VERSION
; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа